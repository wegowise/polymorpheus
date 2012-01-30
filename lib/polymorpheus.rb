module Polymorpheus
  autoload :Adapter, 'polymorpheus/adapter'
  autoload :Interface, 'polymorpheus/interface'
  autoload :Trigger, 'polymorpheus/trigger'

  module ConnectionAdapters
    autoload :SchemaStatements, 'polymorpheus/schema_statements'
  end
end

Polymorpheus::Adapter.register 'mysql2', 'polymorpheus/mysql_adapter'

require 'polymorpheus/railtie' if defined?(Rails)
