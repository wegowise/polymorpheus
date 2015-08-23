require 'active_record'
require 'spec_helper'
require 'sql_logger'
require 'foreigner'
require 'foreigner/connection_adapters/mysql2_adapter'
require 'polymorpheus'
require 'polymorpheus/trigger'
require 'shared_examples'

Polymorpheus::Adapter.load!

describe Polymorpheus::ConnectionAdapters::MysqlAdapter do

  #######################################################
  # Setup
  #######################################################

  before(:all) do
    class << ActiveRecord::Base.connection
      include Polymorpheus::SqlLogger
      alias_method :original_execute, :execute
      alias_method :execute, :log_sql_statements
    end
  end

  after(:all) do
    class << ActiveRecord::Base.connection
      alias_method :execute, :original_execute
    end
  end

  let(:connection) { ActiveRecord::Base.connection }
  let(:sql) { connection.sql_statements }

  def clean_sql(sql_string)
    sql_string.gsub(/^\n\s*/,'').gsub(/\s*\n\s*$/,'')
      .gsub(/\n\s*/,"\n").gsub(/\s*$/,"")
  end

  before do
    connection.clear_sql_history
    subject
  end

  #######################################################
  # Specs
  #######################################################

  describe "migration statements" do
    context "basic case with no uniqueness constraints" do
      include_context "columns with short names"
      let(:options) { {} }

      it_behaves_like "mysql2 migration statements"
    end

    context "when uniqueness constraint is specified as true" do
      include_context "columns with short names"
      let(:options) { { :unique => true } }
      let(:unique_key_sql) do
        %{ CREATE UNIQUE INDEX pfk_pets_dogid ON pets (dog_id)
           CREATE UNIQUE INDEX pfk_pets_kittyid ON pets (kitty_id) }
      end
      let(:remove_indices_sql) do
        %{ DROP INDEX pfk_pets_kittyid ON pets
           DROP INDEX pfk_pets_dogid ON pets }
      end

      it_behaves_like "mysql2 migration statements"
    end

    context "specifying uniqueness constraint as a string" do
      include_context "columns with short names"
      let(:options) { { :unique => 'field1' } }
      let(:unique_key_sql) do
        %{ CREATE UNIQUE INDEX pfk_pets_dogid_field1 ON pets (dog_id, field1)
           CREATE UNIQUE INDEX pfk_pets_kittyid_field1 ON pets (kitty_id, field1) }
      end
      let(:remove_indices_sql) do
        %{ DROP INDEX pfk_pets_kittyid_field1 ON pets
           DROP INDEX pfk_pets_dogid_field1 ON pets }
      end

      it_behaves_like "mysql2 migration statements"
    end

    context "specifying uniqueness constraint as an array" do
      include_context "columns with short names"
      let(:options) { { :unique => [:foo, :bar] } }
      let(:unique_key_sql) do
        %{ CREATE UNIQUE INDEX pfk_pets_dogid_foo_bar ON pets (dog_id, foo, bar)
           CREATE UNIQUE INDEX pfk_pets_kittyid_foo_bar ON pets (kitty_id, foo, bar) }
      end
      let(:remove_indices_sql) do
        %{ DROP INDEX pfk_pets_kittyid_foo_bar ON pets
           DROP INDEX pfk_pets_dogid_foo_bar ON pets }
      end

      it_behaves_like "mysql2 migration statements"
    end

    context "specifying an on update constraint" do
      include_context "columns with short names"
      let(:options) { { :on_update => :cascade } }
      let(:fkey_sql) do
        %{ ALTER TABLE `pets` ADD CONSTRAINT `pets_dog_id_fk` FOREIGN KEY (`dog_id`) REFERENCES `dogs`(id) ON UPDATE CASCADE
           ALTER TABLE `pets` ADD CONSTRAINT `pets_kitty_id_fk` FOREIGN KEY (`kitty_id`) REFERENCES `cats`(name) ON UPDATE CASCADE }
      end

      it_behaves_like "mysql2 migration statements"
    end

    context "specifying on delete and on update constraints" do
      include_context "columns with short names"
      let(:options) { { :on_update => :cascade, :on_delete => :restrict } }
      let(:fkey_sql) do
        %{ ALTER TABLE `pets` ADD CONSTRAINT `pets_dog_id_fk` FOREIGN KEY (`dog_id`) REFERENCES `dogs`(id) ON DELETE RESTRICT ON UPDATE CASCADE
           ALTER TABLE `pets` ADD CONSTRAINT `pets_kitty_id_fk` FOREIGN KEY (`kitty_id`) REFERENCES `cats`(name) ON DELETE RESTRICT ON UPDATE CASCADE }
      end

      it_behaves_like "mysql2 migration statements"
    end

    context "when table and column names combined are very long" do
      include_context "columns with long names"

      it_behaves_like "mysql2 migration statements"
    end
  end

  describe "#triggers" do
    let(:trigger1) { double(Trigger, :name => '1') }
    let(:trigger2) { double(Trigger, :name => '2') }

    before do
      connection.stub_sql('show triggers', [:trigger1, :trigger2])
      Trigger.stub(:new).with(:trigger1).and_return(trigger1)
      Trigger.stub(:new).with(:trigger2).and_return(trigger2)
    end

    specify do
      connection.triggers.should == [trigger1, trigger2]
    end
  end
end
