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

        # Set belongs_to associations
        builder.associations.each do |association|
          belongs_to association.name.to_sym
        end

        # Class constant defining the keys
        const_set "#{polymorphic_api}_keys".upcase, builder.association_keys

        # Helper methods and constants
        define_method "#{polymorphic_api}_types" do
          builder.association_names
        end

        define_method "#{polymorphic_api}_active_key" do
          builder.active_association_key(self)
        end

        define_method "#{polymorphic_api}_query_condition" do
          builder.query_condition(self)
        end

        # Getter method
        define_method polymorphic_api do
          builder.get_associated_object(self)
        end

        # Setter method
        define_method "#{polymorphic_api}=" do |object_to_associate|
          builder.set_associated_object(self, object_to_associate)
        end

        # Private method called as part of validation
        # Validate that there is exactly one associated object
        define_method "polymorphic_#{polymorphic_api}_relationship_is_valid" do
          builder.validate_associations(self)
        end
        private "polymorphic_#{polymorphic_api}_relationship_is_valid"

      end

      def validates_polymorph(polymorphic_api)
        validate "polymorphic_#{polymorphic_api}_relationship_is_valid"
      end

    end

  end
end
