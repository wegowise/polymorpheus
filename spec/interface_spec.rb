require 'active_record'
require 'polymorpheus'
require 'spec_helper'
require 'support/class_defs'

describe '.belongs_to_polymorph' do
  let(:hero) { Hero.create! }
  let(:villain) { Villain.create! }
  let(:superhero) { Superhero.create! }
  let(:alien_demigod) { AlienDemigod.create! }

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

describe '.has_many_as_polymorph' do
  it 'sets conditions on association to ensure we retrieve correct result' do
    hero = Hero.create!
    hero.story_arcs.to_sql
      .should match_sql(%{SELECT `story_arcs`.* FROM `story_arcs`
                          WHERE `story_arcs`.`hero_id` = #{hero.id}
                          AND `story_arcs`.`villain_id` IS NULL})
  end

  it 'supports existing conditions on the association' do
    villain = Villain.create!
    villain.story_arcs.to_sql
      .should match_sql(%{SELECT `story_arcs`.* FROM `story_arcs`
                          WHERE `story_arcs`.`villain_id` = #{villain.id}
                          AND `story_arcs`.`hero_id` IS NULL
                          ORDER BY id DESC})
  end

  it 'returns the correct result when used with new records' do
    villain = Villain.create!
    story_arc = StoryArc.create!(villain: villain, issue_id: 10)
    Hero.new.story_arcs.where(issue_id: 10).should == []
  end

  it 'sets conditions on associations with enough specificity that they work
  in conjunction with has_many :through relationships' do
    hero = Hero.create!
    hero.battles.to_sql
      .should match_sql(%{SELECT `battles`.* FROM `battles`
                          INNER JOIN `story_arcs`
                          ON `battles`.`id` = `story_arcs`.`battle_id`
                          WHERE `story_arcs`.`hero_id` = 16
                          AND `story_arcs`.`villain_id` IS NULL})
  end

  it 'uses the correct association table name when used in conjunction with a
  join condition' do
    battle = Battle.create!
    battle.heros.to_sql
      .should match_sql(%{SELECT `heros`.* FROM `heros`
                          INNER JOIN `story_arcs`
                          ON `heros`.`id` = `story_arcs`.`hero_id`
                          WHERE `story_arcs`.`battle_id` = #{battle.id}})

    battle.heros.joins(:story_arcs).to_sql
      .should match_sql(%{SELECT `heros`.* FROM `heros`
                          INNER JOIN `story_arcs` `story_arcs_heros`
                          ON `story_arcs_heros`.`hero_id` = `heros`.`id`
                          AND `story_arcs_heros`.`villain_id` IS NULL
                          INNER JOIN `story_arcs`
                          ON `heros`.`id` = `story_arcs`.`hero_id`
                          WHERE `story_arcs`.`battle_id` = #{battle.id}})
  end
end

describe '.validates_polymorph' do
  let(:hero) { Hero.create! }
  let(:villain) { Villain.create! }

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
