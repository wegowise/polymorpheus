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

  specify do
    expect(subject.name).to eq(name)
    expect(subject.event).to eq(event)
    expect(subject.table).to eq(table)
    expect(subject.statement).to eq(statement)
    expect(subject.timing).to eq(timing)
    expect(subject.created).to eq(created)
    expect(subject.sql_mode).to eq(sql_mode)
    expect(subject.definer).to eq(definer)
    expect(subject.charset).to eq(charset)
    expect(subject.collation_connection).to eq(collation_connection)
    expect(subject.db_collation).to eq(db_collation)

    expect(subject.columns).to eq(%w{dog_id kitty_id})

    expect(subject.schema_statement)
      .to eq(%{  add_polymorphic_triggers(:pets, ["dog_id", "kitty_id"])})
  end
end
