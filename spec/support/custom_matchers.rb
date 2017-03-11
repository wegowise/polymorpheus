RSpec::Matchers.define :be_association do |association_name|
  match do |actual|
    expect(actual)
      .to be_instance_of(Polymorpheus::InterfaceBuilder::Association)
    expect(actual.name).to eq(association_name.to_s)
  end
end

RSpec::Matchers.define :match_associations do |*association_names|
  match do |actual|
    expect(actual.length).to eq(association_names.length)
    actual.each_with_index do |item, ind|
      expect(item).to be_association(association_names[ind])
    end
  end
end

RSpec::Matchers.define :match_sql do |expected|
  match do |actual|
    expect(format(expected)).to eq(format(actual))
  end

  failure_message do |actual|
    "expected the following SQL statements to match:
    #{format(actual)}
    #{format(expected)}"
  end

  def format(sql)
    sql.gsub(/\s+/, ' ')
  end
end
