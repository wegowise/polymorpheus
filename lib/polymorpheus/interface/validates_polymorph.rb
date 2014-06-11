module Polymorpheus
  module Interface
    module ValidatesPolymorph
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
