require 'active_record'
require 'spec_helper'
require 'sql_logger'
require 'foreigner'
require 'foreigner/connection_adapters/mysql2_adapter'
require 'polymorpheus'

Polymorpheus::Adapter.load!

describe "Polymorpheus" do
  class << ActiveRecord::Base.connection
    include Polymorpheus::SqlLogger
  end

  let(:connection) { ActiveRecord::Base.connection }
  let(:sql) { connection.sql_statements }

  describe "add_polymorphic_constraints" do
    before do
      connection.add_polymorphic_constraints 'pets',
        { 'dog_id' => 'dogs.id', 'kitty_id' => 'cats.name' }
    end

    it "executes the correct sql statements" do
      clean_sql(sql.join("\n")).should == clean_sql(%{
        DROP TRIGGER IF EXISTS pets_unique_polyfk_on_INSERT
        DROP TRIGGER IF EXISTS pets_unique_polyfk_on_UPDATE
        CREATE TRIGGER pets_unique_polyfk_on_INSERT BEFORE INSERT ON pets
          FOR EACH ROW
            BEGIN
              IF(IF(NEW.dog_id IS NULL, 0, 1) + IF(NEW.kitty_id IS NULL, 0, 1)) <> 1 THEN
                SET NEW = 'Error';
              END IF;
            END
        CREATE TRIGGER pets_unique_polyfk_on_UPDATE BEFORE UPDATE ON pets
          FOR EACH ROW
            BEGIN
              IF(IF(NEW.dog_id IS NULL, 0, 1) + IF(NEW.kitty_id IS NULL, 0, 1)) <> 1 THEN
                SET NEW = 'Error';
              END IF;
            END

        ALTER TABLE `pets` ADD CONSTRAINT `pets_dog_id_fk` FOREIGN KEY (`dog_id`) REFERENCES `dogs`(id)
        ALTER TABLE `pets` ADD CONSTRAINT `pets_kitty_id_fk` FOREIGN KEY (`kitty_id`) REFERENCES `cats`(name)
      })
    end

  end

  def clean_sql(sql_string)
    sql_string.gsub(/^\n\s*/,'').gsub(/\s*\n\s*$/,'').gsub(/\n\s*/,"\n")
  end

end
