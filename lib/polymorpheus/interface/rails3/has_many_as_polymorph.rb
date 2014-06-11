module Polymorpheus
  module Interface
    module HasManyAsPolymorph
      def has_many_as_polymorph(association, options = {})
        options.symbolize_keys!
        fkey = name.foreign_key

        class_name = options[:class_name] || association.to_s.classify

        options[:conditions] = proc do
          keys = class_name.constantize
                  .const_get('POLYMORPHEUS_ASSOCIATIONS')
                  .map(&:foreign_key)
          keys.delete(fkey)

          nil_columns = keys.reduce({}) { |hash, key| hash.merge!(key => nil) }

          if self.is_a?(ActiveRecord::Associations::JoinDependency::JoinAssociation)
            { aliased_table_name => nil_columns }
          else
            { association => nil_columns }
          end
        end

        has_many association, options
      end
    end
  end
end
