module Polymorpheus
  module ConnectionAdapters
    module MysqlAdapter

      INSERT = 'INSERT'
      UPDATE = 'UPDATE'

      # See the README for more information about the use of these methods.
      #
      # table:    a string equal to the name of the db table
      #
      # columns:  a hash, with keys equal to the column names in the table we
      #           are operating on, and values indicating the foreign key
      #           association through the form "table.column".
      #
      #           For example:
      #
      #             {
      #               'employee_id' => 'employees.ssn',
      #               'product_id' => 'products.id'
      #             }
      #
      #           This indicates that the `employee_id` column in `table`
      #           should have a foreign key constraint connecting it to the
      #           `ssn` column in the `employees` table, and the `product_id`
      #           column should have a foreign key constraint with the `id`
      #           column in the `products` table.
      #
      # options:  a hash, accepting the following options
      #
      #   :unique
      #
      #       If the columns hash was specified as above, and :unique is true:
      #
      #         { :unique => true }
      #
      #       Then this creates a uniqueness constraint in the database that
      #       will ensure that any given employee_id can only be in the table
      #       once, and that any given product_id can only be in the table
      #       once.
      #
      #       Alternatively, you can supply a column name or array of column
      #       names to the :unique option:
      #
      #         { :unique => 'picture_url' }
      #
      #       This will allow an employee_id (or product_id) to appear multiple
      #       times in the table, but no two employee IDs would be able to have
      #       the same picture_url.
      #
      #    :on_delete
      #
      #        Action that happens ON DELETE. Valid values are :nullify,
      #        :cascade and :restrict.
      #
      #    :on_update
      #
      #        Action that happens ON UPDATE. Valid values are :nullify,
      #        :cascade and :restrict.


      def add_polymorphic_constraints(table, columns, options={})
        column_names = columns.keys.sort
        add_polymorphic_triggers(table, column_names)
        options.symbolize_keys!
        if options[:unique].present?
          poly_create_indexes(table, column_names, Array(options[:unique]))
        end

        column_names.each do |col_name|
          ref_table, ref_col = columns[col_name].to_s.split('.')
          fk_options = {
            :column => col_name,
            :name => "#{table}_#{col_name}_fk",
            :primary_key => (ref_col || 'id' )
          }.merge(generate_constraints(options))
          add_foreign_key(table, ref_table, fk_options)
        end
      end

      def remove_polymorphic_constraints(table, columns, options = {})
        poly_drop_triggers(table, columns.keys.sort)
        columns.each do |(col, reference)|
          remove_foreign_key table, :column => col, :name => "#{table}_#{col}_fk"
        end
        if options[:unique].present?
          poly_remove_indexes(table, columns.keys, Array(options[:unique]))
        end
      end

      def triggers
        execute("show triggers").collect {|t| Polymorpheus::Trigger.new(t) }
      end

      #
      # DO NOT USE THIS METHOD DIRECTLY
      #
      # it will not create the foreign key relationships you want. the only
      # reason it is here is because it is used by the schema dumper, since
      # the schema dump will contains separate statements for foreign keys,
      # and we don't want to duplicate those
      def add_polymorphic_triggers(table, column_names)
        column_names.sort!
        poly_drop_triggers(table, column_names)
        poly_create_triggers(table, column_names)
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
        if unique_cols == [true]
          unique_cols = [column]
        else
          unique_cols = [column] + unique_cols
        end
        name = poly_index_name(table, unique_cols)
        execute %{
          CREATE UNIQUE INDEX #{name} ON #{table} (#{unique_cols.join(', ')})
        }
      end

      def poly_remove_index(table, column, unique_cols)
        if unique_cols == [true]
          unique_cols = [column]
        else
          unique_cols = [column] + unique_cols
        end
        name = poly_index_name(table, unique_cols)
        execute %{ DROP INDEX #{name} ON #{table} }
      end

      def poly_index_name(table, columns)
        prefix = "pfk_#{table}_"
        generate_name prefix, columns
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
        col_length = (64 - prefix.length) / columns.length

        prefix +
          columns.map { |c| c.to_s.gsub('_','').first(col_length-1) }.join('_')
      end

      def generate_constraints(options)
        options.slice(:on_delete, :on_update)
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

if ::Polymorpheus.require_foreigner?
  require 'foreigner/connection_adapters/mysql2_adapter'
  require 'polymorpheus/mysql_adapter/foreigner_constraints'
end
