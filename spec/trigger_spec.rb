require 'polymorpheus'
require 'polymorpheus/trigger'

describe Trigger do

  let(:name) { "pets_unique_polyfk_on_INSERT" }
  let(:event) { "INSERT" }
  let(:table) { "pets"}
  let(:statement) do
    %{BEGIN
        IF(IF(NEW.dog_id IS NULL, 0, 1) + IF(NEW.kitty_id IS NULL, 0, 1)) <> 1 THEN
          SET NEW = 'Error';
        END IF;
      END}
  end
  let(:timing) { "BEFORE" }
  let(:created) { nil }
  let(:sql_mode) { "" }
  let(:definer) { "production@%" }
  let(:charset) { "utf8" }
  let(:collation_connection) { "utf8_general_ci" }
  let(:db_collation) { "utf8_unicode_ci" }

  subject do
    Trigger.new([name, event, table, statement, timing, created, sql_mode,
                 definer, charset, collation_connection, db_collation])
  end

  its(:name) { should == name }
  its(:event) { should == event }
  its(:table) { should == table }
  its(:statement) { should == statement }
  its(:timing) { should == timing }
  its(:created) { should == created }
  its(:sql_mode) { should == sql_mode }
  its(:definer) { should == definer }
  its(:charset) { should == charset }
  its(:collation_connection) { should == collation_connection }
  its(:db_collation) { should == db_collation }

  its(:columns) { should == %w{dog_id kitty_id} }

end
