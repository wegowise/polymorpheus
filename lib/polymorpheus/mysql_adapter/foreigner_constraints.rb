module Polymorpheus
  module ConnectionAdapters
    module MysqlAdapter
      def generate_constraints(options)
        constraints = []

        ['delete', 'update'].each do |event|
          option = "on_#{event}".to_sym
          next unless options.has_key?(option) &&
                      options[option].respond_to?(:to_sym)

          action = case options[option].to_sym
            when :nullify then 'SET NULL'
            when :cascade then 'CASCADE'
            when :restrict then 'RESTRICT'
            else
              fail ArgumentError, <<-EOS
'#{options[option]}' is not supported for :on_update or :on_delete.
Supported values are: :nullify, :cascade, :restrict
              EOS
          end

          constraints << "ON #{event.upcase} #{action}"
        end

        { :options => constraints.join(' ') }
      end
    end
  end
end
