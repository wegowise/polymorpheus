module Polymorpheus
  autoload :Adapter, 'polymorpheus/adapter'
  autoload :Interface, 'polymorpheus/interface'
  autoload :InterfaceBuilder, 'polymorpheus/interface_builder'
  autoload :Trigger, 'polymorpheus/trigger'
  autoload :SchemaDumper, 'polymorpheus/schema_dumper'

  class InterfaceBuilder
    autoload :Association, 'polymorpheus/interface_builder/association'
  end

  module ConnectionAdapters
    autoload :SchemaStatements, 'polymorpheus/schema_statements'
  end
end

Polymorpheus::Adapter.register 'mysql2', 'polymorpheus/mysql_adapter'

require 'polymorpheus/railtie' if defined?(Rails)
