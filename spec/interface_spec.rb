require 'active_record'
require 'polymorpheus'
require 'spec_helper'
require 'support/class_defs'

describe '.has_many_as_polymorph' do
  it 'sets conditions on association to ensure we retrieve correct result' do
    man = Man.create!
    man.shoes.to_sql.squish
      .should == %{SELECT `shoes`.* FROM `shoes`
                   WHERE `shoes`.`man_id` = 1
                   AND `shoes`.`woman_id` IS NULL}.squish
  end

  it 'supports existing conditions on the association' do
    woman = Woman.create!
    woman.shoes.to_sql.squish
      .should == %{SELECT `shoes`.* FROM `shoes`
                   WHERE `shoes`.`woman_id` = 1
                   AND `shoes`.`man_id` IS NULL
                   ORDER BY id DESC}.squish
  end

  it 'returns the correct result when used with new records' do
    woman = Woman.create!
    shoe = Shoe.create!(woman: woman, other_id: 10)
    Man.new.shoes.where(other_id: 10).should == []
  end
end

describe "polymorphic interface" do

  let(:man) { Man.create! }
  let(:woman) { Woman.create! }
  let(:gentleman) { Gentleman.create! }
  let(:knight) { Knight.create! }

  specify { Shoe::POLYMORPHEUS_ASSOCIATIONS.should == %w[man woman] }
  specify { Glove::POLYMORPHEUS_ASSOCIATIONS.should == %w[gentleman
                                                          gentlewoman] }

  describe "setter methods for ActiveRecord objects" do
    let(:shoe) { Shoe.new(attributes) }
    let(:attributes) { {} }

    it "sets the correct attribute value for the setter" do
      shoe.wearer = man
      shoe.man_id.should == man.id
      shoe.woman_id.should == nil
    end

    it "sets competing associations to nil" do
      shoe.wearer = man
      shoe.man_id.should == man.id
      shoe.wearer = woman
      shoe.woman_id.should == woman.id
      shoe.man_id.should == nil
    end

    it "throws an error if the assigned object isn't a valid type" do
      dog = Dog.create!
      expect { shoe.wearer = dog }
        .to raise_error(Polymorpheus::Interface::InvalidTypeError,
                        "Invalid type. Must be one of {man, woman}")
    end

    it "does not throw an error if the assigned object is a subclass of a
    valid type" do
      expect { shoe.wearer = gentleman }.not_to raise_error
      shoe.man_id.should == gentleman.id
    end

    it "does not throw an error if the assigned object is a descendant of a
    valid type" do
      expect { shoe.wearer = knight }.not_to raise_error
      shoe.man_id.should == knight.id
    end
  end

  describe "setter methods for objects inheriting from ActiveRecord objects" do
    let(:glove) { Glove.new }

    it "throws an error if the assigned object is an instance of the parent
    ActiveRecord class" do
      expect { glove.wearer = man }.to raise_error(
        Polymorpheus::Interface::InvalidTypeError,
        "Invalid type. Must be one of {gentleman, gentlewoman}"
      )
    end

    it "works if the assigned object is of the specified class" do
      expect { glove.wearer = gentleman }.not_to raise_error
      glove.gentleman_id.should == gentleman.id
    end

    it "works if the assigned object is an instance of a child class" do
      expect { glove.wearer = knight }.not_to raise_error
      glove.gentleman_id.should == knight.id
    end
  end

  describe '.validates_polymorph validation' do
    specify { Shoe.new(wearer: man).valid?.should == true }
    specify { Shoe.new(wearer: woman).valid?.should == true }
    specify { Shoe.new(man_id: man.id).valid?.should == true }
    specify { Shoe.new(man: man).valid?.should == true }
    specify { Shoe.new(man: Man.new).valid?.should == true }

    it 'is invalid if no association is specified' do
      shoe = Shoe.new
      shoe.valid?.should == false
      shoe.errors[:base].should ==
        ["You must specify exactly one of the following: {man, woman}"]
    end

    it 'is invalid if multiple associations are specified' do
      shoe = Shoe.new(man_id: man.id, woman_id: woman.id)
      shoe.valid?.should == false
      shoe.errors[:base].should ==
        ["You must specify exactly one of the following: {man, woman}"]
    end
  end

  describe '#polymorpheus exposed interface method' do
    subject(:interface) { shoe.polymorpheus }

    context 'when there is no relationship defined' do
      let(:shoe) { Shoe.new }

      its(:associations) { should match_associations(:man, :woman) }
      its(:active_association) { should == nil }
      its(:query_condition) { should == nil }
    end

    context 'when there is are multiple relationships defined' do
      let(:shoe) { Shoe.new(man_id: man.id, woman_id: woman.id) }

      its(:associations) { should match_associations(:man, :woman) }
      its(:active_association) { should == nil }
      its(:query_condition) { should == nil }
    end

    context 'when there is one relationship defined through the id value' do
      let(:shoe) { Shoe.new(man_id: man.id) }

      its(:associations) { should match_associations(:man, :woman) }
      its(:active_association) { be_association(:man) }
      its(:query_condition) { should == { 'man_id' => man.id } }
    end

    context 'when there is one relationship defined through the setter' do
      let(:shoe) { Shoe.new(wearer: man) }

      its(:associations) { should match_associations(:man, :woman) }
      its(:active_association) { be_association(:man) }
      its(:query_condition) { should == { 'man_id' => man.id } }
    end

    context 'when there is one association, to a new record' do
      let(:new_man) { Man.new }
      let(:shoe) { Shoe.new(wearer: new_man) }

      its(:associations) { should match_associations(:man, :woman) }
      its(:active_association) { be_association(:man) }
      its(:query_condition) { should == nil }
    end
  end

end
