require 'active_record'
require 'polymorpheus'
require 'stringio'

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: ENV.fetch('DB_NAME', 'polymorpheus_test'),
  host: ENV.fetch('DB_HOST', '127.0.0.1'),
  password: ENV.fetch('DB_PASSWORD', ''),
  port: ENV.fetch('DB_PORT', '3306'),
  username: ENV.fetch('DB_USERNAME', 'root')
)

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
