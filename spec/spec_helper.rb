ActiveRecord::Base.establish_connection({
  adapter: 'mysql2',
  username: 'root',
  password: '',
  host: 'localhost',
  database: 'polymorphicTest'
})

ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table table
end

ActiveRecord::Schema.define do
  create_table :shoes do |t|
    t.integer :man_id
    t.integer :woman_id
  end
  create_table :gloves do |t|
    t.integer :man_id
    t.integer :woman_id
  end
  create_table :men do |t|
    t.string :type
  end
  create_table :women
  create_table :dogs
end

