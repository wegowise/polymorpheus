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
      base.extend(BelongsToPolymorphic)
      base.extend(HasManyAsPolymorph)
      base.extend(ValidatesPolymorph)
    end
  end
end
