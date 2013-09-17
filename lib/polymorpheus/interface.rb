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
