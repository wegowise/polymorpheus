module Polymorpheus
  autoload :Adapter, 'polymorpheus/adapter'
  autoload :Interface, 'polymorpheus/interface'
  autoload :InterfaceBuilder, 'polymorpheus/interface_builder'
  autoload :Trigger, 'polymorpheus/trigger'
  autoload :SchemaDumper, 'polymorpheus/schema_dumper'

  module Interface
    autoload :BelongsToPolymorphic, 'polymorpheus/interface/belongs_to_polymorphic'
    autoload :ValidatesPolymorph, 'polymorpheus/interface/validates_polymorph'
    autoload :HasManyAsPolymorph, 'polymorpheus/interface/has_many_as_polymorph'
  end

  class InterfaceBuilder
    autoload :Association, 'polymorpheus/interface_builder/association'
  end

  module ConnectionAdapters
    autoload :SchemaStatements, 'polymorpheus/schema_statements'
  end
end

Polymorpheus::Adapter.register 'mysql2', 'polymorpheus/mysql_adapter'
Polymorpheus::Adapter.register 'postgresql', 'polymorpheus/postgresql_adapter'

require 'polymorpheus/railtie' if defined?(Rails)
