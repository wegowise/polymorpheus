require 'spec_helper'

describe Polymorpheus::Interface::HasManyAsPolymorph do
  before do
    create_table :story_arcs do |t|
      t.references :hero
      t.references :villain
      t.references :battle
      t.references :issue
    end
    create_table :battles
    create_table :heros
    create_table :issues
    create_table :villains
  end

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
                          WHERE `story_arcs`.`hero_id` = #{hero.id}
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
