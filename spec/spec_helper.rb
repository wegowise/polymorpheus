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


RSpec::Matchers.define :be_association do |association_name|
  match do |actual|
    actual.should be_instance_of(Polymorpheus::InterfaceBuilder::Association)
    actual.name.should == association_name.to_s
  end
end

RSpec::Matchers.define :match_associations do |*association_names|
  match do |actual|
    actual.length.should == association_names.length
    actual.each_with_index do |item, ind|
      item.should be_association(association_names[ind])
    end
  end
end
