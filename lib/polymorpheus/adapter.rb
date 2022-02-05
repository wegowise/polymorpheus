module Polymorpheus
  class Adapter

    class << self
      @@registered_adapters = {}

      def register(adapter_name, file_name)
        @@registered_adapters[adapter_name] = file_name
      end

      def load!
        if file = @@registered_adapters[configured_adapter]
          require file
        end
      end

      def configured_adapter
        if ActiveRecord::Base.respond_to?(:connection_db_config)
          ActiveRecord::Base.connection_db_config.adapter # ActiveRecord >= 6.1
        else
          ActiveRecord::Base.connection_pool.spec.config[:adapter]
        end
      end
    end

  end
end
