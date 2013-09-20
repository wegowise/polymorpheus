ActiveRecord::Base.establish_connection({
  adapter: 'mysql2',
  username: 'travis',
  database: 'polymorpheus_test'
})

ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table table
end

ActiveRecord::Schema.define do
  create_table :shoes do |t|
    t.integer :man_id
    t.integer :woman_id
    t.integer :other_id
  end
  create_table :gloves do |t|
    t.integer :gentleman_id
    t.integer :gentlewoman_id
  end
  create_table :men do |t|
    t.string :type
  end
  create_table :women
  create_table :dogs
end
