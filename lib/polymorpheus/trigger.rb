class Trigger

  attr_accessor :name, :event, :table, :statement, :timing, :created, :sql_mode,
                :definer, :charset, :collation_connection, :db_collation

  def initialize(arr)
    raise ArgumentError unless arr.is_a?(Array) && arr.length == 11
    [:name, :event, :table, :statement, :timing, :created, :sql_mode,
      :definer, :charset, :collation_connection, :db_collation].
    each_with_index do |attr, ind|
      self.send("#{attr}=", arr[ind])
    end
  end

  def columns
    /IF\((.*)\) \<\> 1/.match(self.statement) do |match|
      match[1].split(' + ').collect do |submatch|
        /NEW\.([^ ]*)/.match(submatch)[1]
      end
    end
  end

  def schema_statement
    # note that we don't need to worry about unique indices or foreign keys
    # because separate schema statements will be generated for them
    "add_polymorphic_triggers(#{table}, #{columns})"
  end

end
