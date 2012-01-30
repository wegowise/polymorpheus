module Polymorpheus
  module ConnectionAdapters
    module MysqlAdapter

      INSERT = 'INSERT'
      UPDATE = 'UPDATE'

      # See the README for explanations regarding the use of these methods
      #
      # table:    a string equal to the name of the db table
      #
      # columns:  a hash, with keys equal to the column names in the table we
      #           are operating on, and values indicating the foreign key
      #           association through the form "table.column". so,
      #             { 'employee_id' => 'employees.ssn',
      #               'product_id' => 'products.id' }
      #           indicates that the `employee_id` column in `table` should have
      #           a foreign key constraint connecting it to the `ssn` column
      #           in the `employees` table, and the `product_id` column should
      #           have a foreign key constraint with the `id` column in the
      #           `products` table
      #
      # options:  a hash, corrently only accepts one option that allows us to
      #           add an additional uniqueness constraint. so if the columns
      #           hash was specified as above, and we supplied options of
      #             { :unique => 'picture_url' }
      #           then this would create a uniqueness constraint in the database
      #           that would ensure that no two employees could have the same
      #           picture_url and no two products could have the same
      #           picture_url
      #           (it would allow and employee and a product to have the same
      #           picture_url)

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

