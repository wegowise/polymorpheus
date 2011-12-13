module Polymorpheus
  module ConnectionAdapters
    module SchemaStatements
      def self.included(base)
        base::AbstractAdapter.class_eval do
          include Polymorpheus::ConnectionAdapters::AbstractAdapter
        end
      end
    end

    module AbstractAdapter
      def add_polymorphic_constraints(table, columns, options = {})
      end
    end
  end
end

