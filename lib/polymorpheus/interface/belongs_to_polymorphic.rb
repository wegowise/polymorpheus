module Polymorpheus
  module Interface
    module BelongsToPolymorphic
      def belongs_to_polymorphic(*association_names, options)
        polymorphic_api = options.delete(:as)
        builder = Polymorpheus::InterfaceBuilder.new(polymorphic_api,
                                                     association_names,
                                                     options)

        # The POLYMORPHEUS_ASSOCIATIONS constant is useful for two reasons:
        #
        # 1. It is useful for other classes to be able to ask this class
        #    about its polymorphic relationship.
        #
        # 2. It prevents a class from defining multiple polymorphic
        #    relationships. Doing so would be a bad idea from a design
        #    standpoint, and we don't want to allow for (and support)
        #    that added complexity.
        #
        const_set('POLYMORPHEUS_ASSOCIATIONS', builder.association_names)

        # Set belongs_to associations
        builder.associations.each do |association|
          belongs_to association.name.to_sym, **association.options
        end

        # Exposed interface for introspection
        define_method 'polymorpheus' do
          builder.exposed_interface(self)
        end

        # Getter method
        define_method polymorphic_api do
          builder.get_associated_object(self)
        end

        # Setter method
        define_method "#{polymorphic_api}=" do |object_to_associate|
          builder.set_associated_object(self, object_to_associate)
        end
      end
    end
  end
end
