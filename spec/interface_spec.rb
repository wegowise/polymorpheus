require 'active_record'
require 'polymorpheus'
require 'spec_helper'
require 'support/class_defs'

describe '.belongs_to_polymorph' do
  let(:hero) { Hero.create! }
  let(:villain) { Villain.create! }
  let(:superhero) { Superhero.create! }
  let(:alien_demigod) { AlienDemigod.create! }

  specify do
    expect(StoryArc::POLYMORPHEUS_ASSOCIATIONS).to eq(%w[hero villain])
  end
  specify do
    expect(Superpower::POLYMORPHEUS_ASSOCIATIONS)
      .to eq(%w[superhero supervillain])
  end

  describe 'setter methods for ActiveRecord objects' do
    let(:story_arc) { StoryArc.new(attributes) }
    let(:attributes) { {} }

    it 'sets the correct attribute value for the setter' do
      story_arc.character = hero
      expect(story_arc.hero_id).to eq(hero.id)
      expect(story_arc.villain_id).to eq(nil)
    end

    it 'sets competing associations to nil' do
      story_arc.character = hero
      expect(story_arc.hero_id).to eq(hero.id)
      story_arc.character = villain
      expect(story_arc.villain_id).to eq(villain.id)
      expect(story_arc.hero_id).to eq(nil)
    end

    it "throws an error if the assigned object isn't a valid type" do
      tree = Tree.create!
      expect { story_arc.character = tree }.to(
        raise_error(
          Polymorpheus::Interface::InvalidTypeError,
          'Invalid type. Must be one of {hero, villain}'
        )
      )
    end

    it 'does not throw an error if the assigned object is a subclass of a ' \
       'valid type' do
      expect { story_arc.character = superhero }.not_to raise_error
      expect(story_arc.hero_id).to eq(superhero.id)
    end

    it 'does not throw an error if the assigned object is a descendant of a ' \
       'valid type' do
      expect { story_arc.character = alien_demigod }.not_to raise_error
      expect(story_arc.hero_id).to eq(alien_demigod.id)
    end
  end

  describe 'setter methods for objects inheriting from ActiveRecord objects' do
    let(:superpower) { Superpower.new }

    it 'throws an error if the assigned object is an instance of the parent ' \
       'ActiveRecord class' do
      expect { superpower.wielder = hero }.to raise_error(
        Polymorpheus::Interface::InvalidTypeError,
        'Invalid type. Must be one of {superhero, supervillain}'
      )
    end

    it 'works if the assigned object is of the specified class' do
      expect { superpower.wielder = superhero }.not_to raise_error
      expect(superpower.superhero_id).to eq(superhero.id)
    end

    it 'works if the assigned object is an instance of a child class' do
      expect { superpower.wielder = alien_demigod }.not_to raise_error
      expect(superpower.superhero_id).to eq(alien_demigod.id)
    end
  end

  describe '#polymorpheus exposed interface method' do
    subject(:interface) { story_arc.polymorpheus }

    context 'when there is no relationship defined' do
      let(:story_arc) { StoryArc.new }

      specify do
        expect(interface.associations).to match_associations(:hero, :villain)
        expect(interface.active_association).to eq(nil)
        expect(interface.query_condition).to eq(nil)
      end
    end

    context 'when there is are multiple relationships defined' do
      let(:story_arc) { StoryArc.new(hero_id: hero.id, villain_id: villain.id) }

      specify do
        expect(interface.associations).to match_associations(:hero, :villain)
        expect(interface.active_association).to eq(nil)
        expect(interface.query_condition).to eq(nil)
      end
    end

    context 'when there is one relationship defined through the id value' do
      let(:story_arc) { StoryArc.new(hero_id: hero.id) }

      specify do
        expect(interface.associations).to match_associations(:hero, :villain)
        expect(interface.active_association).to be_association(:hero)
        expect(interface.query_condition).to eq({ 'hero_id' => hero.id })
      end
    end

    context 'when there is one relationship defined through the setter' do
      let(:story_arc) { StoryArc.new(character: hero) }

      specify do
        expect(interface.associations).to match_associations(:hero, :villain)
        expect(interface.active_association).to be_association(:hero)
        expect(interface.query_condition).to eq({ 'hero_id' => hero.id })
      end
    end

    context 'when there is one association, to a new record' do
      let(:new_hero) { Hero.new }
      let(:story_arc) { StoryArc.new(character: new_hero) }

      specify do
        expect(interface.associations).to match_associations(:hero, :villain)
        expect(interface.active_association).to be_association(:hero)
        expect(interface.query_condition).to eq(nil)
      end
    end
  end
end

describe '.has_many_as_polymorph' do
  it 'sets conditions on association to ensure we retrieve correct result' do
    hero = Hero.create!
    expect(hero.story_arcs.to_sql)
      .to match_sql(%{SELECT `story_arcs`.* FROM `story_arcs`
                      WHERE `story_arcs`.`hero_id` = #{hero.id}
                      AND `story_arcs`.`villain_id` IS NULL})
  end

  it 'supports existing conditions on the association' do
    villain = Villain.create!
    expect(villain.story_arcs.to_sql)
      .to match_sql(%{SELECT `story_arcs`.* FROM `story_arcs`
                      WHERE `story_arcs`.`villain_id` = #{villain.id}
                      AND `story_arcs`.`hero_id` IS NULL
                      ORDER BY id DESC})
  end

  it 'returns the correct result when used with new records' do
    villain = Villain.create!
    StoryArc.create!(villain: villain, issue_id: 10)
    expect(Hero.new.story_arcs.where(issue_id: 10)).to eq([])
  end

  it 'sets conditions on associations with enough specificity that they work ' \
     'in conjunction with has_many :through relationships' do
    hero = Hero.create!
    expect(hero.battles.to_sql)
      .to match_sql(%{SELECT `battles`.* FROM `battles`
                      INNER JOIN `story_arcs`
                      ON `battles`.`id` = `story_arcs`.`battle_id`
                      WHERE `story_arcs`.`hero_id` = #{hero.id}
                      AND `story_arcs`.`villain_id` IS NULL})
  end

  it 'uses the correct association table name when used in conjunction with ' \
     'a join condition' do
    battle = Battle.create!
    expect(battle.heros.to_sql)
      .to match_sql(%{SELECT `heros`.* FROM `heros`
                      INNER JOIN `story_arcs`
                      ON `heros`.`id` = `story_arcs`.`hero_id`
                      WHERE `story_arcs`.`battle_id` = #{battle.id}})

    expect(battle.heros.joins(:story_arcs).to_sql)
      .to match_sql(%{SELECT `heros`.* FROM `heros`
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

  specify { expect(StoryArc.new(character: hero)).to be_valid }
  specify { expect(StoryArc.new(character: villain)).to be_valid }
  specify { expect(StoryArc.new(hero_id: hero.id)).to be_valid }
  specify { expect(StoryArc.new(hero: hero)).to be_valid }
  specify { expect(StoryArc.new(hero: Hero.new)).to be_valid }

  it 'is invalid if no association is specified' do
    story_arc = StoryArc.new
    expect(story_arc).to_not be_valid
    expect(story_arc.errors[:base])
      .to eq(['You must specify exactly one of the following: {hero, villain}'])
  end

  it 'is invalid if multiple associations are specified' do
    story_arc = StoryArc.new(hero_id: hero.id, villain_id: villain.id)
    expect(story_arc).to_not be_valid
    expect(story_arc.errors[:base])
      .to eq(['You must specify exactly one of the following: {hero, villain}'])
  end
end

describe 'association options' do
  it 'without options' do
    expect(Drawing.new.association(:book).reflection.inverse_of).to eq(nil)
    expect(Drawing.new.association(:binder).reflection.inverse_of).to eq(nil)
    expect(Book.new.association(:drawings).reflection.inverse_of).to eq(nil)
    expect(Binder.new.association(:drawings).reflection.inverse_of).to eq(nil)
  end

  it 'with options' do
    expect(Picture.new.association(:web_page).reflection.inverse_of.name)
      .to eq(:pictures)
    expect(Picture.new.association(:printed_work).reflection.inverse_of.name)
      .to eq(:pictures)
    expect(WebPage.new.association(:pictures).reflection.inverse_of.name)
      .to eq(:web_page)
    expect(PrintedWork.new.association(:pictures).reflection.inverse_of.name)
      .to eq(:printed_work)
  end
end
