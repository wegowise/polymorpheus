module Polymorpheus
  module ConnectionAdapters
    module MysqlAdapter

      INSERT = 'INSERT'
      UPDATE = 'UPDATE'

      # Suppose I have a table named "pets" with columns dog_id and kitty_id, and I want them to
      # have a polymorphic database constraint such that dog_id references the "id" column of the
      # dogs table, and kitty_id references the "name" column of the "cats" table. then my inputs
      # to this method would be:
      #   table:    'pets'
      #   columns:  { 'dog_id' => 'dogs.id', 'kitty_id' => 'cats.name' }
      #
      # UNIQUENESS CONSTRAINTS:
      #
      # Suppose the pets table also has a 'person_id' column, and we want to impose a uniqueness
      # constraint such that a given cat or dog can only be associated with the person one time
      # We can specify this in the options as follows:
      #   options:  :unique => 'person_id'

      def add_polymorphic_constraints(table, columns, options = {})
        poly_drop_triggers(table)
        poly_create_triggers(table, columns.keys)
        options.symbolize_keys!
        index_suffix = options[:index_suffix]
        if options[:unique].present?
          poly_create_indexes(table, columns.keys, Array(options[:unique]), index_suffix)
        end
        columns.each do |(col, reference)|
          ref_table, ref_col = reference.to_s.split('.')
          add_foreign_key table, ref_table, :column => col, :primary_key => (ref_col || 'id')
        end
      end

      def remove_polymorphic_constraints(table, columns, options = {})
        poly_drop_triggers(table)
        index_suffix = options[:index_suffix]
        columns.each do |(col, reference)|
          ref_table, ref_col = reference.to_s.split('.')
          remove_foreign_key table, ref_table
        end
        if options[:unique].present?
          poly_remove_indexes(table, columns.keys, Array(options[:unique]), index_suffix)
        end
      end


      ##########################################################################
      private

      def poly_trigger_name(table, action)
        "#{table}_unique_polyfk_on_#{action}"
      end

      def poly_drop_trigger(table, action)
        execute %{DROP TRIGGER IF EXISTS #{poly_trigger_name(table, action)}}
      end

      def poly_create_trigger(table, action, columns)
        sql = "CREATE TRIGGER #{poly_trigger_name(table, action)} BEFORE #{action} ON #{table}\n" +
              "FOR EACH ROW\n" +
              "BEGIN\n"
        colchecks = columns.collect { |col| "IF(NEW.#{col} IS NULL, 0, 1)" }.
                            join(' + ')
        sql += "IF(#{colchecks}) <> 1 THEN\n" +
                "SET NEW = 'Error';\n" +
                "END IF;\n" +
                "END"

        execute sql
      end

      def poly_drop_triggers(table)
        poly_drop_trigger(table, 'INSERT')
        poly_drop_trigger(table, 'UPDATE')
      end

      def poly_create_triggers(table, columns)
        poly_create_trigger(table, 'INSERT', columns)
        poly_create_trigger(table, 'UPDATE', columns)
      end

      def poly_create_index(table, column, unique_cols, index_suffix)
        unique_cols = unique_cols.collect(&:to_s)
        name = poly_index_name(table, column, unique_cols, index_suffix)
        execute %{
          CREATE UNIQUE INDEX #{name} ON #{table} (#{column},#{unique_cols.join(',')})
        }
      end

      def poly_remove_index(table, column, unique_cols, index_suffix)
        unique_cols = unique_cols.collect(&:to_s)
        name = poly_index_name(table, column, unique_cols, index_suffix)
        execute %{ DROP INDEX #{name} ON #{table} }
      end

      def poly_index_name(table, column, unique_cols, index_suffix)
        index_suffix ||= unique_cols.join('_and_')
        "index_#{table}_on_#{column}_and_#{index_suffix}"
      end

      def poly_create_indexes(table, columns, unique_cols, index_suffix)
        columns.each do |column|
          poly_create_index(table, column, unique_cols, index_suffix)
        end
      end

      def poly_remove_indexes(table, columns, unique_cols, index_suffix)
        columns.each do |column|
          poly_remove_index(table, column, unique_cols, index_suffix)
        end
      end

    end
  end
end

[:MysqlAdapter, :Mysql2Adapter].each do |adapter|
  begin
    ActiveRecord::ConnectionAdapters.const_get(adapter).class_eval do
      include Polymorpheus::ConnectionAdapters::MysqlAdapter
    end
  rescue
  end
end

