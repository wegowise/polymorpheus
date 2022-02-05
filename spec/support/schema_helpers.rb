module SchemaHelpers
  def create_table(name, options = {})
    options.merge!(force: true)
    ActiveRecord::Schema.define do
      create_table(name, **options) do |t|
        yield(t) if block_given?
      end
    end
    name.to_s.classify.constantize.reset_column_information
  end

  def drop_table(name)
    ActiveRecord::Schema.define do
      drop_table(name)
    end
  end
end
