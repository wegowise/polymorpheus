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

describe Shoe do

  let(:shoe) { Shoe.new(attributes) }
  let(:man) { Man.create! }
  let(:woman) { Woman.create! }

  describe "class level constant" do
    specify { Shoe::WEARER_KEYS.should == ["man_id", "woman_id"] }
  end

  describe "helper methods" do
    specify { Shoe.new.wearer_types.should == ["man", "woman"] }
  end

  it "make the dynamically defined validation method private" do
    Shoe.private_instance_methods.
      include?(:polymorphic_wearer_relationship_is_valid).should be_true
  end

  shared_examples_for "invalid polymorphic relationship" do
    specify { shoe.wearer.should == nil }
    specify { shoe.wearer_active_key.should == nil }
    specify { shoe.wearer_query_condition.should == nil }
    it "validates appropriately" do
      shoe.valid?.should be_false
      shoe.errors[:base].should ==
        ["You must specify exactly one of the following: {man, woman}"]
    end
  end

  context "when there is no relationship defined" do
    let(:attributes) { {} }
    it_should_behave_like "invalid polymorphic relationship"
  end

  context "when there are multiple relationships defined" do
    let(:attributes) { { man_id: man.id, woman_id: woman.id } }
    it_should_behave_like "invalid polymorphic relationship"
  end

  context "when there is exactly one relationship defined" do
    shared_examples_for "valid polymorphic relationship" do
      specify { shoe.wearer.should == man }
      specify { shoe.wearer_active_key.should == 'man_id' }
      specify { shoe.wearer_query_condition.should == { 'man_id' => man.id } }
    end
    context "and we have specified it via the id value" do
      let(:attributes) { { man_id: man.id } }
      it_should_behave_like "valid polymorphic relationship"
    end
    context "and we have specified it via the id value" do
      let(:attributes) { { man: man } }
      it_should_behave_like "valid polymorphic relationship"
    end
  end

end
