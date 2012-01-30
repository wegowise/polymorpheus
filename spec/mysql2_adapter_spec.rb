require 'active_record'
require 'spec_helper'
require 'sql_logger'
require 'foreigner'
require 'foreigner/connection_adapters/mysql2_adapter'
require 'polymorpheus'
require 'polymorpheus/trigger'

Polymorpheus::Adapter.load!

describe "Polymorpheus" do

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

  describe "#add_polymorphic_constraints" do

    subject { connection.add_polymorphic_constraints table, columns }

    let(:table) { 'pets' }
    let(:columns) { { 'kitty_id' => 'cats.name', 'dog_id' => 'dogs.id' } }

    before do
      connection.clear_sql_history
      subject
    end

    context "when the table and column names are not too long" do
      it "executes the correct sql statements" do
        clean_sql(sql.join("\n")).should == clean_sql(%{
          DROP TRIGGER IF EXISTS pfki_pets_dogid_kittyid
          DROP TRIGGER IF EXISTS pfku_pets_dogid_kittyid
          CREATE TRIGGER pfki_pets_dogid_kittyid BEFORE INSERT ON pets
            FOR EACH ROW
              BEGIN
                IF(IF(NEW.dog_id IS NULL, 0, 1) + IF(NEW.kitty_id IS NULL, 0, 1)) <> 1 THEN
                  SET NEW = 'Error';
                END IF;
              END
          CREATE TRIGGER pfku_pets_dogid_kittyid BEFORE UPDATE ON pets
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

    context "when the table and column names combined are very long" do
      let(:table) { 'bicycles' }
      let(:columns) do
         { 'im_too_cool_to_vote_and_ill_only_ride_a_fixie' => 'hipster.id',
           'really_im_not_doping_i_just_practice_a_lot' => 'professional.id' }
      end

      it "executes the correct sql statements" do
        clean_sql(sql.join("\n")).should == clean_sql(%{
          DROP TRIGGER IF EXISTS pfki_bicycles_imtoocooltovoteandillonl_reallyimnotdopingijustpr
          DROP TRIGGER IF EXISTS pfku_bicycles_imtoocooltovoteandillonl_reallyimnotdopingijustpr
          CREATE TRIGGER pfki_bicycles_imtoocooltovoteandillonl_reallyimnotdopingijustpr BEFORE INSERT ON bicycles
            FOR EACH ROW
              BEGIN
                IF(IF(NEW.im_too_cool_to_vote_and_ill_only_ride_a_fixie IS NULL, 0, 1) + IF(NEW.really_im_not_doping_i_just_practice_a_lot IS NULL, 0, 1)) <> 1 THEN
                  SET NEW = 'Error';
                END IF;
              END
          CREATE TRIGGER pfku_bicycles_imtoocooltovoteandillonl_reallyimnotdopingijustpr BEFORE UPDATE ON bicycles
            FOR EACH ROW
              BEGIN
                IF(IF(NEW.im_too_cool_to_vote_and_ill_only_ride_a_fixie IS NULL, 0, 1) + IF(NEW.really_im_not_doping_i_just_practice_a_lot IS NULL, 0, 1)) <> 1 THEN
                  SET NEW = 'Error';
                END IF;
              END

          ALTER TABLE `bicycles` ADD CONSTRAINT `bicycles_im_too_cool_to_vote_and_ill_only_ride_a_fixie_fk` FOREIGN KEY (`im_too_cool_to_vote_and_ill_only_ride_a_fixie`) REFERENCES `hipster`(id)
          ALTER TABLE `bicycles` ADD CONSTRAINT `bicycles_really_im_not_doping_i_just_practice_a_lot_fk` FOREIGN KEY (`really_im_not_doping_i_just_practice_a_lot`) REFERENCES `professional`(id)
        })
      end
    end
  end


  describe "#triggers" do
    let(:trigger1) { stub(Trigger, :name => '1') }
    let(:trigger2) { stub(Trigger, :name => '2') }

    before do
      connection.stub_sql('show triggers', [:trigger1, :trigger2])
      Trigger.stub(:new).with(:trigger1).and_return(trigger1)
      Trigger.stub(:new).with(:trigger2).and_return(trigger2)
    end

    specify do
      connection.triggers.should == [trigger1, trigger2]
    end
  end

  def clean_sql(sql_string)
    sql_string.gsub(/^\n\s*/,'').gsub(/\s*\n\s*$/,'').gsub(/\n\s*/,"\n")
  end

end
