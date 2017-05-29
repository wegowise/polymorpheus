module ConnectionHelpers
  def add_polymorphic_constraints(*args)
    connection.add_polymorphic_constraints(*args)
  end

  def data_sources
    if ActiveRecord::VERSION::MAJOR >= 5
      ActiveRecord::Base.connection.data_sources
    else
      ActiveRecord::Base.connection.tables
    end
  end

  def remove_polymorphic_constraints(*args)
    connection.remove_polymorphic_constraints(*args)
  end

  def triggers
    connection.triggers
  end
end
