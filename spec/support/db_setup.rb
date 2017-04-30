ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table table
end

ActiveRecord::Schema.define do
  create_table :heros
  create_table :villains
  create_table :superheros
  create_table :alien_demigods
  create_table :supervillains
  create_table :trees
  create_table :drawings
  create_table :books
  create_table :binders
  create_table :pictures
  create_table :web_pages
  create_table :printed_works

  create_table :story_arcs do |t|
    t.integer :hero_id
    t.integer :villain_id
    t.integer :battle_id
    t.integer :issue_id
  end

  create_table :battles

  create_table :superpowers do |t|
    t.integer :superhero_id
    t.integer :supervillain_id
  end
end
