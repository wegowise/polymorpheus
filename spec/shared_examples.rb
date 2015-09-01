shared_examples_for 'mysql2 add sql for polymorphic constraints' do
  describe "#add_polymorphic_constraints" do
    before { connection.add_polymorphic_constraints(table, columns, options) }

    specify do
      clean_sql(sql.join("\n")).should == clean_sql(full_constraints_sql)
    end
  end
end

shared_examples_for 'mysql2 add sql for polymorphic triggers' do
  describe "#add_polymorphic_triggers" do
    before { connection.add_polymorphic_triggers(table, columns.keys) }

    specify do
      clean_sql(sql.join("\n")).should == clean_sql(trigger_sql)
    end
  end
end

shared_examples_for 'mysql2 remove sql for polymorphic constraints' do
  describe "#remove_polymorphic_constraints" do
    before { connection.remove_polymorphic_constraints(table, columns, options) }

    specify do
      clean_sql(sql.join("\n")).should == clean_sql(remove_constraints_sql)
    end
  end
end

shared_examples_for "mysql2 migration statements" do
  it_behaves_like 'mysql2 add sql for polymorphic constraints'
  it_behaves_like 'mysql2 add sql for polymorphic triggers'
  it_behaves_like 'mysql2 remove sql for polymorphic constraints'
end

shared_context "columns with short names" do
  let(:table) { 'pets' }
  let(:columns) { { 'kitty_id' => 'cats.name', 'dog_id' => 'dogs.id' } }
  let(:trigger_sql) do
    %{
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
    }
  end
  let(:fkey_sql) do
    %{
      ALTER TABLE `pets` ADD CONSTRAINT `pets_dog_id_fk` FOREIGN KEY (`dog_id`) REFERENCES `dogs`(id)
      ALTER TABLE `pets` ADD CONSTRAINT `pets_kitty_id_fk` FOREIGN KEY (`kitty_id`) REFERENCES `cats`(name)
    }
  end
  let(:unique_key_sql) { '' }
  let(:full_constraints_sql) { trigger_sql + unique_key_sql + fkey_sql }
  let(:remove_indices_sql) { '' }
  let(:remove_constraints_sql) do
    %{
      DROP TRIGGER IF EXISTS pfki_pets_dogid_kittyid
      DROP TRIGGER IF EXISTS pfku_pets_dogid_kittyid
      ALTER TABLE `pets` DROP FOREIGN KEY `pets_kitty_id_fk`
      ALTER TABLE `pets` DROP FOREIGN KEY `pets_dog_id_fk`
    } +
    remove_indices_sql
  end
end

shared_context "columns with long names" do
  let(:table) { 'bicycles' }
  let(:columns) do
     { 'im_too_cool_to_vote_and_ill_only_ride_a_fixie' => 'hipster.id',
       'really_im_not_doping_i_just_practice_a_lot' => 'professional.id' }
  end
  let(:options) { {} }

  let(:trigger_sql) do
    %{
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
    }
  end

  let(:fkey_sql) do
    %{
      ALTER TABLE `bicycles` ADD CONSTRAINT `bicycles_im_too_cool_to_vote_and_ill_only_ride_a_fixie_fk` FOREIGN KEY (`im_too_cool_to_vote_and_ill_only_ride_a_fixie`) REFERENCES `hipster`(id)
      ALTER TABLE `bicycles` ADD CONSTRAINT `bicycles_really_im_not_doping_i_just_practice_a_lot_fk` FOREIGN KEY (`really_im_not_doping_i_just_practice_a_lot`) REFERENCES `professional`(id)
    }
  end

  let(:full_constraints_sql) { trigger_sql + fkey_sql }
  let(:remove_constraints_sql) do
    %{
      DROP TRIGGER IF EXISTS pfki_bicycles_imtoocooltovoteandillonl_reallyimnotdopingijustpr
      DROP TRIGGER IF EXISTS pfku_bicycles_imtoocooltovoteandillonl_reallyimnotdopingijustpr
      ALTER TABLE `bicycles` DROP FOREIGN KEY `bicycles_im_too_cool_to_vote_and_ill_only_ride_a_fixie_fk`
      ALTER TABLE `bicycles` DROP FOREIGN KEY `bicycles_really_im_not_doping_i_just_practice_a_lot_fk`
    }
  end
end
