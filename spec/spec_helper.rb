require 'active_record'
require 'polymorpheus'
require 'stringio'

require 'support/active_record/connection_adapters/abstract_mysql_adapter'

ActiveRecord::Base.establish_connection({
  adapter: 'mysql2',
  username: 'travis',
  database: 'polymorpheus_test'
})

Dir[File.dirname(__FILE__) + '/support/*.rb'].sort.each { |path| require path }

Polymorpheus::Adapter.load!

# This is normally done via a Railtie in non-testing situations.
ActiveRecord::SchemaDumper.class_eval { include Polymorpheus::SchemaDumper }
ActiveRecord::Migration.verbose = false

RSpec.configure do |config|
  config.order = :random
  Kernel.srand config.seed

  config.include ConnectionHelpers
  config.include SchemaHelpers
  config.include SqlTestHelpers

  config.after do
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
end
