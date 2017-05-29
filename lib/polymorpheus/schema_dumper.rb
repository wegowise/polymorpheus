module Polymorpheus
  module SchemaDumper
    extend ActiveSupport::Concern

    included do
      alias_method :tables_without_triggers, :tables
      alias_method :tables, :tables_with_triggers
    end

    def tables_with_triggers(stream)
      tables_without_triggers(stream)

      if @connection.respond_to?(:triggers)
        @connection.triggers.collect(&:schema_statement).uniq.each do |statement|
          stream.puts statement
        end
      end

      stream.puts
    end
  end
 end
