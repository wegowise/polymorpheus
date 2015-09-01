[![Build Status](https://travis-ci.org/wegowise/polymorpheus.png?branch=master)](https://travis-ci.org/wegowise/polymorpheus)
[![Code Climate](https://codeclimate.com/github/wegowise/polymorpheus.png)](https://codeclimate.com/github/wegowise/polymorpheus)

# Polymorpheus
**Polymorphic relationships in Rails that keep your database happy with almost
no setup**

### Installation

If you are using Bundler, you can add the gem to your Gemfile:

```ruby
# with Rails >= 4.2
gem 'polymorpheus'
```

Or:

```ruby
# with Rails < 4.2
gem 'foreigner'
gem 'polymorpheus'
```

### Background
* **What is polymorphism?** [Rails Guides has a great overview of what
  polymorphic relationships are and how Rails handles them](
  http://guides.rubyonrails.org/association_basics.html#polymorphic-associations)

* **If you don't think database constraints are important** then [here is a
  presentation that might change your mind](
  http://bostonrb.org/presentations/databases-constraints-polymorphism). If
  you're still not convinced, this gem won't be relevant to you.

* **What's wrong with Rails' built-in approach to polymorphism?** Using Rails,
  polymorphism is implemented in the database using a `type` column and an `id`
  column, where the `id` column references one of multiple other tables,
  depending on the `type`. This violates the basic principle that one column in
  a database should mean to one thing, and it prevents us from setting up any
  sort of database constraint on the `id` column.


## Basic Use

We'll outline the use case to mirror the example [outline in the Rails Guides](
http://guides.rubyonrails.org/association_basics.html#polymorphic-associations):

* You have a `Picture` object that can belong to an `Imageable`, where an
  `Imageable` is a polymorphic representation of either an `Employee` or a
  `Product`.

With Polymorpheus, you would define this relationship as follows:

**Database migration**

```ruby
class SetUpPicturesTable < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.integer :employee_id
      t.integer :product_id
    end

    add_polymorphic_constraints 'pictures',
      { 'employee_id' => 'employees.id',
        'product_id' => 'products.id' }
  end

  def self.down
    remove_polymorphic_constraints 'pictures',
      { 'employee_id' => 'employees.id',
        'product_id' => 'products.id' }

    drop_table :pictures
  end
end
```

**ActiveRecord model definitions**

```ruby
class Picture < ActiveRecord::Base
  belongs_to_polymorphic :employee, :product, :as => :imageable
  validates_polymorph :imageable
end

class Employee < ActiveRecord::Base
  has_many_as_polymorph :pictures
end

class Product < ActiveRecord::Base
  has_many_as_polymorph :pictures
end
```

That's it!

Now let's review what we've done.


## Database Migration

* Instead of `imageable_type` and `imageable_id` columns in the pictures table,
  we've created explicit columns for the `employee_id` and `product_id`
* The `add_polymorphic_constraints` call takes care of all of the database
  constraints you need, without you needing to worry about sql! Specifically it:
  * Creates foreign key relationships in the database as specified. So in this
    example, we have specified that the `employee_id` column in the `pictures`
    table should have a foreign key constraint with the `id` column of the
    `employees` table.
  * Creates appropriate triggers in our database that make sure that exactly one
    or the other of `employee_id` or `product_id` are specified for a given
    record. An exception will be raised if you try to save a database record
    that contains both or none of them.
* **Options for migrations**: There are options to customize the foreign keys
  generated by Polymorpheus and add uniqueness constraints. For more info
  on this, [read the wiki entry](https://github.com/wegowise/polymorpheus/wiki/Migration-options).

## Model definitions

* The `belongs_to_polymorphic` declaration in the `Picture` class specifies the
  polymorphic relationship. It provides all of the same methods that Rails does
  for its built-in polymorphic relationships, plus a couple additional features.
  See the Interface section below.
* `validates_polymorph` declaration: checks that exactly one of the possible
  polymorphic relationships is specified. In this example, either an
  `employee_id` or `product_id` must be specified -- if both are nil or if both
  are non-nil a validation error will be added to the object.
* The `has_many_as_polymorph` declaration generates a normal Rails `has_many`
  declaration, but adds a constraint that ensures that the correct records are
  retrieved. This means you can still use the same conditions with it that you
  would use with a `has_many` association (such as `:order`, `:class_name`,
  etc.). Specifically, the `has_many_as_polymorph` declaration in the `Employee`
  class of the example above is equivalant to
  `has_many :pictures, { product_id: nil }`
  and the `has_many_as_polymorph` declaration in the `Product` class is
  equivalent to `has_many :pictures, { employee_id: nil }`

## Requirements / Support

* Currently the gem only supports MySQL. Please feel free to fork and submit a
  (well-tested) pull request if you want to add Postgres support.
* This gem is tested and has been tested for Rails 2.3.8, 3.0.x, 3.1.x, 3.2.x,
  and 4.0.0
* For Rails 3.1+, you'll still need to use `up` and `down` methods in your
  migrations.

## Interface

The nice thing about Polymorpheus is that under the hood it builds on top of the
Rails conventions you're already used to which means that you can interface with
your polymorphic relationships in simple, familiar ways. It also lets you
introspect on the polymorphic associations.

Let's use the example above to illustrate.

```
sam = Employee.create(name: 'Sam')
nintendo = Product.create(name: 'Nintendo')

pic = Picture.new
 => #<Picture id: nil, employee_id: nil, product_id: nil>

pic.imageable
 => nil

# The following two options are equivalent, just as they are normally with
# ActiveRecord:
#   pic.employee = sam
#   pic.employee_id = sam.id

# If we specify an employee, the imageable getter method will return that employee:
pic.employee = sam;
pic.imageable
 => #<Employee id: 1, name: "Sam">
pic.employee
 => #<Employee id: 1, name: "Sam">
pic.product
 => nil

# If we specify a product, the imageable getting will return that product:
Picture.new(product: nintendo).imageable
 => #<Product id: 1, name: "Nintendo">

# But, if we specify an employee and a product, the getter will know this makes
# no sense and return nil for the imageable:
Picture.new(employee: sam, product: nintendo).imageable
 => nil

# A `polymorpheus` instance method is attached to your model that allows you
# to introspect:

pic.polymorpheus.associations
 => [
      #<Polymorpheus::InterfaceBuilder::Association:0x007f88b5528b00 @name="employee">,
      #<Polymorpheus::InterfaceBuilder::Association:0x007f88b55289c0 @name="picture">
    ]

pic.polymorpheus.associations.map(&:name)
 => ["employee", "product"]

pic.polymorpheus.associations.map(&:key)
 => ["employee_id", "product_id"]

pic.polymorpheus.active_association
 => #<Polymorpheus::InterfaceBuilder::Association:0x007f88b5528b00 @name="employee">,

pic.polymorpheus.query_condition
 => {"employee_id"=>"1"}
```

## Credits and License

* This gem was written by [Barun Singh](https://github.com/barunio)
* It uses the [Foreigner gem](https://github.com/matthuhiggins/foreigner) under
  the hood for Rails < 4.2.

polymorpheus is Copyright © 2011-2015 Barun Singh and [WegoWise](
http://wegowise.com). It is free software, and may be redistributed under the
terms specified in the LICENSE file.
