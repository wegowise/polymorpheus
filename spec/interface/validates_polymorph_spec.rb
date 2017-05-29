require 'spec_helper'

describe Polymorpheus::Interface::ValidatesPolymorph do
  let(:hero) { Hero.create! }
  let(:villain) { Villain.create! }

  before do
    create_table(:story_arcs) do |t|
      t.references :hero
      t.references :villain
    end
    create_table(:heros)
    create_table(:villains)
  end

  specify { StoryArc.new(character: hero).valid?.should == true }
  specify { StoryArc.new(character: villain).valid?.should == true }
  specify { StoryArc.new(hero_id: hero.id).valid?.should == true }
  specify { StoryArc.new(hero: hero).valid?.should == true }
  specify { StoryArc.new(hero: Hero.new).valid?.should == true }

  it 'is invalid if no association is specified' do
    story_arc = StoryArc.new
    story_arc.valid?.should == false
    story_arc.errors[:base].should ==
      ["You must specify exactly one of the following: {hero, villain}"]
  end

  it 'is invalid if multiple associations are specified' do
    story_arc = StoryArc.new(hero_id: hero.id, villain_id: villain.id)
    story_arc.valid?.should == false
    story_arc.errors[:base].should ==
      ["You must specify exactly one of the following: {hero, villain}"]
  end
end
