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
