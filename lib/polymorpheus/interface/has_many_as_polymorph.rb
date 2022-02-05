module Polymorpheus
  module Interface
    module HasManyAsPolymorph
      def has_many_as_polymorph(association, scope = nil, options = {})
        if scope.instance_of?(Hash)
          options = scope
          scope = nil
        end

        options.symbolize_keys!
        fkey = name.foreign_key

        class_name = options[:class_name] || association.to_s.classify

        conditions = proc do
          keys = class_name.constantize
                  .const_get('POLYMORPHEUS_ASSOCIATIONS')
                  .map(&:foreign_key)
          keys.delete(fkey)

          nil_columns = keys.reduce({}) { |hash, key| hash.merge!(key => nil) }

          relation = where(nil_columns)
          relation = scope.call.merge(relation) unless scope.nil?
          relation
        end

        has_many association, conditions, options
      end
    end
  end
end
