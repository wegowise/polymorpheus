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
        ActiveRecord::Base.connection_pool.spec.config[:adapter]
      end
    end

  end
end
