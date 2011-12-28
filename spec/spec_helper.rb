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
  create_table :men
  create_table :women
end

