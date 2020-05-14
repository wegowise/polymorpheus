require 'spec_helper'

describe Polymorpheus::Trigger do
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

  let(:trigger) do
    described_class.new(
      [
        name,
        event,
        table,
        statement,
        timing,
        created,
        sql_mode,
        definer,
        charset,
        collation_connection,
        db_collation
      ]
    )
  end

  specify { expect(trigger.name).to eq name }
  specify { expect(trigger.event).to eq event }
  specify { expect(trigger.table).to eq table }
  specify { expect(trigger.statement).to eq statement }
  specify { expect(trigger.timing).to eq timing }
  specify { expect(trigger.created).to eq created }
  specify { expect(trigger.sql_mode).to eq sql_mode }
  specify { expect(trigger.definer).to eq definer }
  specify { expect(trigger.charset).to eq charset }
  specify { expect(trigger.collation_connection).to eq collation_connection }
  specify { expect(trigger.db_collation).to eq db_collation }

  specify { expect(trigger.columns).to eq %w[dog_id kitty_id] }

  specify do
    expect(trigger.schema_statement).to eq %{  add_polymorphic_triggers(:pets, ["dog_id", "kitty_id"])}
  end
end
