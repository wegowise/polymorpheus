require 'spec_helper'

describe Polymorpheus::Interface::BelongsToPolymorphic do
  let(:hero) { Hero.create! }
  let(:villain) { Villain.create! }
  let(:superhero) { Superhero.create! }
  let(:alien_demigod) { AlienDemigod.create! }

  before do
    create_table :story_arcs do |t|
      t.references :hero
      t.references :villain
    end
    create_table :heros
    create_table :villains
  end

  specify { StoryArc::POLYMORPHEUS_ASSOCIATIONS.should == %w[hero villain] }
  specify { Superpower::POLYMORPHEUS_ASSOCIATIONS.should == %w[superhero
                                                               supervillain] }

  describe "setter methods for ActiveRecord objects" do
    let(:story_arc) { StoryArc.new(attributes) }
    let(:attributes) { {} }

    it "sets the correct attribute value for the setter" do
      story_arc.character = hero
      story_arc.hero_id.should == hero.id
      story_arc.villain_id.should == nil
    end

    it "sets competing associations to nil" do
      story_arc.character = hero
      story_arc.hero_id.should == hero.id
      story_arc.character = villain
      story_arc.villain_id.should == villain.id
      story_arc.hero_id.should == nil
    end

    it "throws an error if the assigned object isn't a valid type" do
      create_table :trees

      tree = Tree.create!
      expect { story_arc.character = tree }
        .to raise_error(Polymorpheus::Interface::InvalidTypeError,
                        "Invalid type. Must be one of {hero, villain}")
    end

    it "does not throw an error if the assigned object is a subclass of a
    valid type" do
      expect { story_arc.character = superhero }.not_to raise_error
      story_arc.hero_id.should == superhero.id
    end

    it "does not throw an error if the assigned object is a descendant of a
    valid type" do
      expect { story_arc.character = alien_demigod }.not_to raise_error
      story_arc.hero_id.should == alien_demigod.id
    end
  end

  describe "setter methods for objects inheriting from ActiveRecord objects" do
    let(:superpower) { Superpower.new }

    before do
      create_table :superpowers do |t|
        t.references :superhero
        t.references :supervillain
      end
    end

    it "throws an error if the assigned object is an instance of the parent
    ActiveRecord class" do
      expect { superpower.wielder = hero }.to raise_error(
        Polymorpheus::Interface::InvalidTypeError,
        "Invalid type. Must be one of {superhero, supervillain}"
      )
    end

    it "works if the assigned object is of the specified class" do
      expect { superpower.wielder = superhero }.not_to raise_error
      superpower.superhero_id.should == superhero.id
    end

    it "works if the assigned object is an instance of a child class" do
      expect { superpower.wielder = alien_demigod }.not_to raise_error
      superpower.superhero_id.should == alien_demigod.id
    end
  end

  describe '#polymorpheus exposed interface method' do
    subject(:interface) { story_arc.polymorpheus }

    context 'when there is no relationship defined' do
      let(:story_arc) { StoryArc.new }

      its(:associations) { should match_associations(:hero, :villain) }
      its(:active_association) { should == nil }
      its(:query_condition) { should == nil }
    end

    context 'when there is are multiple relationships defined' do
      let(:story_arc) { StoryArc.new(hero_id: hero.id, villain_id: villain.id) }

      its(:associations) { should match_associations(:hero, :villain) }
      its(:active_association) { should == nil }
      its(:query_condition) { should == nil }
    end

    context 'when there is one relationship defined through the id value' do
      let(:story_arc) { StoryArc.new(hero_id: hero.id) }

      its(:associations) { should match_associations(:hero, :villain) }
      its(:active_association) { be_association(:hero) }
      its(:query_condition) { should == { 'hero_id' => hero.id } }
    end

    context 'when there is one relationship defined through the setter' do
      let(:story_arc) { StoryArc.new(character: hero) }

      its(:associations) { should match_associations(:hero, :villain) }
      its(:active_association) { be_association(:hero) }
      its(:query_condition) { should == { 'hero_id' => hero.id } }
    end

    context 'when there is one association, to a new record' do
      let(:new_hero) { Hero.new }
      let(:story_arc) { StoryArc.new(character: new_hero) }

      its(:associations) { should match_associations(:hero, :villain) }
      its(:active_association) { be_association(:hero) }
      its(:query_condition) { should == nil }
    end
  end
end
