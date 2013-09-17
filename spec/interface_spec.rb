require 'active_record'
require 'polymorpheus'
require 'spec_helper'

# this is normally done via a Railtie in non-testing situations
ActiveRecord::Base.send :include, Polymorpheus::Interface

class Shoe < ActiveRecord::Base
  belongs_to_polymorphic :man, :woman, :as => :wearer
  validates_polymorph :wearer
end

class Man < ActiveRecord::Base
end

class Woman < ActiveRecord::Base
end

class Dog < ActiveRecord::Base
end

class Glove < ActiveRecord::Base
  belongs_to_polymorphic :gentleman, :gentlewoman, :as => :wearer
  validates_polymorph :wearer
end

class Gentleman < Man
end

class Knight < Gentleman
end

class Gentlewoman < Woman
end


describe "polymorphic interface" do

  let(:man) { Man.create! }
  let(:woman) { Woman.create! }
  let(:gentleman) { Gentleman.create! }
  let(:knight) { Knight.create! }

  describe "class level constant" do
    specify { Shoe::WEARER_KEYS.should == ["man_id", "woman_id"] }
    specify { Glove::WEARER_KEYS.should == ["gentleman_id", "gentlewoman_id"] }
  end

  describe "helper methods" do
    specify { Shoe.new.wearer_types.should == ["man", "woman"] }
    specify { Glove.new.wearer_types.should == ["gentleman", "gentlewoman"] }
  end

  it "make the dynamically defined validation method private" do
    Shoe.private_instance_methods.
      include?(:polymorphic_wearer_relationship_is_valid).should be_true
  end

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

  context "when there is no relationship defined" do
    let(:shoe) { Shoe.new }

    specify { shoe.wearer.should == nil }
    specify { shoe.wearer_active_key.should == nil }
    specify { shoe.wearer_query_condition.should == nil }

    it "sets validation errors" do
      shoe.valid?.should be_false
      shoe.errors[:base].should ==
        ["You must specify exactly one of the following: {man, woman}"]
    end
end

  context "when there are multiple relationships defined" do
    let(:shoe) { Shoe.new(man_id: man.id, woman_id: woman.id) }

    specify { shoe.wearer.should == nil }
    specify { shoe.wearer_active_key.should == nil }
    specify { shoe.wearer_query_condition.should == nil }

    it "sets validation errors" do
      shoe.valid?.should be_false
      shoe.errors[:base].should ==
        ["You must specify exactly one of the following: {man, woman}"]
    end
  end

  context "when there is exactly one relationship defined" do
    context "and we have specified it via the id value" do
      let(:shoe) { Shoe.new(man_id: man.id) }

      specify { shoe.wearer.should == man }
      specify { shoe.wearer_active_key.should == 'man_id' }
      specify { shoe.wearer_query_condition.should == { 'man_id' => man.id } }
    end

    context "and we have set the associated object directly" do
      let(:shoe) { Shoe.new(man: man) }

      specify { shoe.wearer.should == man }
      specify { shoe.wearer_active_key.should == 'man_id' }
      specify { shoe.wearer_query_condition.should == { 'man_id' => man.id } }
    end

    context "and the record we are linking to is a new record" do
      let(:new_man) { Man.new }
      let(:shoe) { Shoe.new(man: new_man) }

      specify { shoe.wearer.should == new_man }
      specify { shoe.wearer_active_key.should == nil }
      specify { shoe.wearer_query_condition.should be_nil }
    end
  end

end
