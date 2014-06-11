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
      base.extend(BelongsToPolymorphic)
      base.extend(HasManyAsPolymorph)
    end

    module ClassMethods

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
