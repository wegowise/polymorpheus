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

      def add_polymorphic_constraints(table, columns, options={})
        column_names = columns.keys.sort
        poly_drop_triggers(table, column_names)
        poly_create_triggers(table, column_names)
        options.symbolize_keys!
        if options[:unique].present?
          poly_create_indexes(table, columns.keys, Array(options[:unique]))
        end
        column_names.each do |col_name|
          ref_table, ref_col = columns[col_name].to_s.split('.')
          add_foreign_key table, ref_table,
                                 :column => col_name,
                                 :primary_key => (ref_col || 'id')
        end
      end

      def remove_polymorphic_constraints(table, columns, options = {})
        poly_drop_triggers(table, columns.keys.sort)
        columns.each do |(col, reference)|
          ref_table, ref_col = reference.to_s.split('.')
          remove_foreign_key table, ref_table
        end
        if options[:unique].present?
          poly_remove_indexes(table, columns.keys, Array(options[:unique]))
        end
      end


      ##########################################################################
      private

      def poly_trigger_name(table, action, columns)
        prefix = "pfk#{action.first}_#{table}_".downcase
        generate_name prefix, columns.sort
      end

      def poly_drop_trigger(table, action, columns)
        trigger_name = poly_trigger_name(table, action, columns)
        execute %{DROP TRIGGER IF EXISTS #{trigger_name}}
      end

      def poly_create_trigger(table, action, columns)
        trigger_name = poly_trigger_name(table, action, columns)
        colchecks = columns.collect { |col| "IF(NEW.#{col} IS NULL, 0, 1)" }.
                            join(' + ')

        sql = %{
          CREATE TRIGGER #{trigger_name} BEFORE #{action} ON #{table}
            FOR EACH ROW
            BEGIN
              IF(#{colchecks}) <> 1 THEN
                SET NEW = 'Error';
              END IF;
            END}

        execute sql
      end

      def poly_drop_triggers(table, columns)
        poly_drop_trigger(table, 'INSERT', columns)
        poly_drop_trigger(table, 'UPDATE', columns)
      end

      def poly_create_triggers(table, columns)
        poly_create_trigger(table, 'INSERT', columns)
        poly_create_trigger(table, 'UPDATE', columns)
      end

      def poly_create_index(table, column, unique_cols)
        unique_cols = unique_cols.collect(&:to_s)
        name = poly_index_name(table, column, unique_cols)
        execute %{
          CREATE UNIQUE INDEX #{name} ON #{table} (#{column},#{unique_cols.join(',')})
        }
      end

      def poly_remove_index(table, column, unique_cols)
        unique_cols = unique_cols.collect(&:to_s)
        name = poly_index_name(table, column, unique_cols)
        execute %{ DROP INDEX #{name} ON #{table} }
      end

      def poly_index_name(table, column, unique_cols)
        prefix = "pfk_#{table}"
        generate_name prefix, [column] + unique_cols
      end

      def poly_create_indexes(table, columns, unique_cols)
        columns.each do |column|
          poly_create_index(table, column, unique_cols)
        end
      end

      def poly_remove_indexes(table, columns, unique_cols)
        columns.each do |column|
          poly_remove_index(table, column, unique_cols)
        end
      end

      def generate_name(prefix, columns)
        # names can be at most 64 characters long
        length_per_col = (64 - prefix.length) / columns.length

        prefix +
          columns.map { |c| c.gsub('_','').first(length_per_col - 1) }.join('_')
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

