module Polymorpheus
  autoload :Adapter, 'polymorpheus/adapter'
  autoload :Interface, 'polymorpheus/interface'
  autoload :Trigger, 'polymorpheus/trigger'
  autoload :SchemaDumper, 'polymorpheus/schema_dumper'

  module ConnectionAdapters
    autoload :SchemaStatements, 'polymorpheus/schema_statements'
  end
end

Polymorpheus::Adapter.register 'mysql2', 'polymorpheus/mysql_adapter'

require 'polymorpheus/railtie' if defined?(Rails)
