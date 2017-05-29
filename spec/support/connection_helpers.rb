module ConnectionHelpers
  def add_polymorphic_constraints(*args)
    connection.add_polymorphic_constraints(*args)
  end

  def remove_polymorphic_constraints(*args)
    connection.remove_polymorphic_constraints(*args)
  end

  def triggers
    connection.triggers
  end
end
