require 'active_record'
require 'spec_helper'
require 'sql_logger'
require 'polymorpheus'
require 'polymorpheus/trigger'
require 'stringio'

# this is normally done via a Railtie in non-testing situations
ActiveRecord::SchemaDumper.class_eval { include Polymorpheus::SchemaDumper }

describe Polymorpheus::SchemaDumper do

  let(:connection) { ActiveRecord::Base.connection }
  let(:stream) { StringIO.new }

  before do
    # pretend like we have a trigger defined
    connection.stub(:triggers).and_return(
      [Trigger.new(["trigger_name", "INSERT", "pets",
        %{BEGIN
            IF(IF(NEW.dog_id IS NULL, 0, 1) + IF(NEW.kitty_id IS NULL, 0, 1)) <> 1 THEN
              SET NEW = 'Error';
            END IF;
          END},
        "BEFORE", nil, "", "production@%", "utf8", "utf8_general_ci",
        "utf8_unicode_ci"])]
    )

    ActiveRecord::SchemaDumper.dump(connection, stream)
  end

  subject { stream.string }

  let(:schema_statement) do
    %{  add_polymorphic_triggers(:pets, ["dog_id", "kitty_id"])}
  end

  specify "the schema statement is part of the dump" do
    subject.index(schema_statement).should be_a(Integer)
  end

  specify "there is exactly one instance of the schema statement" do
    subject.index(schema_statement).should == subject.rindex(schema_statement)
  end

end
