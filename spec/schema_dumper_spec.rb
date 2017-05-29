require 'spec_helper'

describe Polymorpheus::SchemaDumper do
  let(:connection) { ActiveRecord::Base.connection }
  let(:stream) { StringIO.new }

  before do
    create_table :story_arcs do |t|
      t.references :hero
      t.references :villain
    end
    create_table :heros
    create_table :villains
    ActiveRecord::Base.connection.add_polymorphic_constraints(
      'story_arcs',
      { hero_id: 'heros.id', villain_id: 'villains.id' }
    )

    ActiveRecord::SchemaDumper.dump(connection, stream)
  end

  after do
    drop_table :story_arcs # drop first, due to the foreign key
  end

  subject { stream.string }

  let(:schema_statement) do
    %{  add_polymorphic_triggers(:story_arcs, ["hero_id", "villain_id"])}
  end

  specify "the schema statement is part of the dump" do
    subject.index(schema_statement).should be_a(Integer)
  end

  specify "there is exactly one instance of the schema statement" do
    subject.index(schema_statement).should == subject.rindex(schema_statement)
  end
end
