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

  specify { expect(StoryArc.new(character: hero).valid?).to eq(true) }
  specify { expect(StoryArc.new(character: villain).valid?).to eq(true) }
  specify { expect(StoryArc.new(hero_id: hero.id).valid?).to eq(true) }
  specify { expect(StoryArc.new(hero: hero).valid?).to eq(true) }
  specify { expect(StoryArc.new(hero: Hero.new).valid?).to eq(true) }

  it 'is invalid if no association is specified' do
    story_arc = StoryArc.new
    expect(story_arc.valid?).to eq(false)
    expect(story_arc.errors[:base]).to eq(
      ["You must specify exactly one of the following: {hero, villain}"]
    )
  end

  it 'is invalid if multiple associations are specified' do
    story_arc = StoryArc.new(hero_id: hero.id, villain_id: villain.id)
    expect(story_arc.valid?).to eq(false)
    expect(story_arc.errors[:base]).to eq(
      ["You must specify exactly one of the following: {hero, villain}"]
    )
  end
end
