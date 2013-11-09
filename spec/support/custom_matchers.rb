RSpec::Matchers.define :be_association do |association_name|
  match do |actual|
    actual.should be_instance_of(Polymorpheus::InterfaceBuilder::Association)
    actual.name.should == association_name.to_s
  end
end

RSpec::Matchers.define :match_associations do |*association_names|
  match do |actual|
    actual.length.should == association_names.length
    actual.each_with_index do |item, ind|
      item.should be_association(association_names[ind])
    end
  end
end

RSpec::Matchers.define :match_sql do |expected|
  match do |actual|
    format(expected).should == format(actual)
  end

  failure_message_for_should do |actual|
    "expected the following SQL statements to match:
    #{format(actual)}
    #{format(expected)}"
  end

  def format(sql)
    sql.gsub(/\s+/, ' ')
  end
end
