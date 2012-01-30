# Thanks to matthuhiggins/foreigner gem for the template used here
module Polymorpheus
  class Railtie < Rails::Railtie

    initializer 'polymorpheus.load_adapter' do
      ActiveSupport.on_load :active_record do

        ActiveRecord::Base.send :include, Polymorpheus::Interface

        ActiveRecord::ConnectionAdapters.module_eval do
          include Polymorpheus::ConnectionAdapters::SchemaStatements
        end

        ActiveRecord::SchemaDumper.class_eval do
          include Polymorpheus::SchemaDumper
        end

        Polymorpheus::Adapter.load!
      end
    end

  end
end

