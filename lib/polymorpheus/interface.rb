module Polymorpheus
  module Interface
    class PolymorphicError < ::StandardError; end

    class InvalidTypeError < PolymorphicError
      def initialize(*accepted_classes)
        error = "Invalid type."
        error += " Must be one of {#{accepted_classes.join(', ')}}"
        super(error)
      end
    end

    class AmbiguousTypeError < PolymorphicError
      def initialize
        super("Ambiguous polymorphic interface or object type")
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def belongs_to_polymorphic(*association_names, options)
        polymorphic_api = options[:as]
        builder = Polymorpheus::InterfaceBuilder.new(polymorphic_api,
                                                     association_names)

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
          belongs_to association.name.to_sym
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

      def has_many_as_polymorph(association, options = {})
        options.symbolize_keys!
        conditions = options.fetch(:conditions, {})
        fkey = name.foreign_key

        class_name = options[:class_name] || association.to_s.classify

        options[:conditions] = proc do
          keys = class_name.constantize
                  .const_get('POLYMORPHEUS_ASSOCIATIONS')
                  .map(&:foreign_key)
          keys.delete(fkey)

          nil_columns = keys.reduce({}) { |hash, key| hash.merge!(key => nil) }

          { association => nil_columns }
        end

        has_many association, options
      end

      def validates_polymorph(polymorphic_api)
        validate Proc.new {
          unless polymorpheus.active_association
            association_names = polymorpheus.associations.map(&:name)
            errors.add(:base, "You must specify exactly one of the following: "\
                              "{#{association_names.join(', ')}}")
          end
        }
      end

    end

  end
end
