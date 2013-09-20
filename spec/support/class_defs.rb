# this is normally done via a Railtie in non-testing situations
ActiveRecord::Base.send :include, Polymorpheus::Interface

class Shoe < ActiveRecord::Base
  belongs_to_polymorphic :man, :woman, :as => :wearer
  validates_polymorph :wearer
end

class Man < ActiveRecord::Base
  has_many_as_polymorph :shoes
end

class Woman < ActiveRecord::Base
  has_many_as_polymorph :shoes, order: 'id DESC'
end

class Dog < ActiveRecord::Base
end

class Glove < ActiveRecord::Base
  belongs_to_polymorphic :gentleman, :gentlewoman, :as => :wearer
  validates_polymorph :wearer
end

class Gentleman < Man
end

class Knight < Gentleman
end

class Gentlewoman < Woman
end
