# this is normally done via a Railtie in non-testing situations
ActiveRecord::Base.send :include, Polymorpheus::Interface

# Han Solo is a hero, but not a superhero
class Hero < ActiveRecord::Base
  has_many_as_polymorph :story_arcs
  has_many :battles, through: :story_arcs
end

# Hannibal Lecter is a villain, but not a supervillain
class Villain < ActiveRecord::Base
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many_as_polymorph :story_arcs, -> { order('id DESC') }
  else
    has_many_as_polymorph :story_arcs, order: 'id DESC'
  end

  has_many :battles, through: :story_arcs
end

# Flash is a superhero but not an alien demigod
class Superhero < Hero
end

# Superman is an alien demigod
class AlienDemigod < Superhero
end

# Darkseid is a supervillain
class Supervillain < Villain
end

# All heros and villains have story arcs
class StoryArc < ActiveRecord::Base
  belongs_to_polymorphic :hero, :villain, as: :character
  belongs_to :battle
  validates_polymorph :character
end

class Battle < ActiveRecord::Base
  has_many :story_arcs
  has_many :heros, through: :story_arcs
end

# But only super-people have superpowers
class Superpower < ActiveRecord::Base
  belongs_to_polymorphic :superhero, :supervillain, as: :wielder
end

# Trees, though, are masters of zen. They sway with the wind.
# (Unless this is LOTR, but let's ignore that for now.)
class Tree < ActiveRecord::Base
end
