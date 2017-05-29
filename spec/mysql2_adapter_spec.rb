require 'spec_helper'

describe Polymorpheus::ConnectionAdapters::MysqlAdapter do
  # The foreign key name is not truncated, so the maximum column name
  # length ends up being:  64 - "pets_" - "_fk" == 56
  let(:long_column1) { ('x' * 56).to_sym }
  let(:long_column2) { ('y' * 56).to_sym }

  before do
    create_table(:pets) do |t|
      t.integer :cat_id
      t.integer :dog_id
      t.string :name
      t.string :color
    end

    create_table(:cats)
    create_table(:dogs)

    clear_sql_history
  end

  after do
    drop_table :pets
    drop_table :cats
    drop_table :dogs
  end

  #######################################################
  # Specs
  #######################################################

  describe '#add_polymorphic_constraints' do
    it 'adds foreign keys with no uniqueness constraints' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' }
      )

      should_execute_sql <<-EOS
        DROP TRIGGER IF EXISTS pfki_pets_catid_dogid
        DROP TRIGGER IF EXISTS pfku_pets_catid_dogid
        CREATE TRIGGER pfki_pets_catid_dogid BEFORE INSERT ON pets
          FOR EACH ROW
            BEGIN
              IF(IF(NEW.cat_id IS NULL, 0, 1) + IF(NEW.dog_id IS NULL, 0, 1)) <> 1 THEN
                SET NEW = 'Error';
              END IF;
            END
        CREATE TRIGGER pfku_pets_catid_dogid BEFORE UPDATE ON pets
          FOR EACH ROW
            BEGIN
              IF(IF(NEW.cat_id IS NULL, 0, 1) + IF(NEW.dog_id IS NULL, 0, 1)) <> 1 THEN
                SET NEW = 'Error';
              END IF;
            END

        ALTER TABLE `pets` ADD CONSTRAINT `pets_cat_id_fk`
        FOREIGN KEY (`cat_id`)
        REFERENCES `cats`(id)

        ALTER TABLE `pets` ADD CONSTRAINT `pets_dog_id_fk`
        FOREIGN KEY (`dog_id`)
        REFERENCES `dogs`(id)
      EOS
    end

    it 'adds uniqueness specified with true' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        unique: true
      )

      should_execute_sql <<-EOS
        CREATE UNIQUE INDEX pfk_pets_catid ON pets (cat_id)
        CREATE UNIQUE INDEX pfk_pets_dogid ON pets (dog_id)
      EOS
    end

    it 'adds uniqueness specified with a string' do
      add_polymorphic_constraints('pets', { cat_id: 'cats.id' }, unique: 'name')
      should_execute_sql <<-EOS
        CREATE UNIQUE INDEX pfk_pets_catid_name ON pets (cat_id, name)
      EOS
    end

    it 'adds uniqueness specified as an array' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id' },
        unique: [:name, :color]
      )
      should_execute_sql <<-EOS
        CREATE UNIQUE INDEX pfk_pets_catid_name_color ON pets (cat_id, name, color)
      EOS
    end

    it 'adds an on update constraint' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id' },
        on_update: :cascade
      )
      should_execute_sql <<-EOS
        ALTER TABLE `pets` ADD CONSTRAINT `pets_cat_id_fk`
        FOREIGN KEY (`cat_id`)
        REFERENCES `cats`(id)
        ON UPDATE CASCADE
      EOS
    end

    it 'raises an error when on_update has invalid arguments' do
      expect do
        add_polymorphic_constraints(
          'pets',
          { cat_id: 'cats.id' },
          on_update: :invalid
        )
      end.to raise_error ArgumentError
    end

    it 'adds an on delete constraint' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id' },
        on_delete: :cascade
      )
      should_execute_sql <<-EOS
        ALTER TABLE `pets` ADD CONSTRAINT `pets_cat_id_fk`
        FOREIGN KEY (`cat_id`)
        REFERENCES `cats`(id)
        ON DELETE CASCADE
      EOS
    end

    it 'raises an error when on_delete has invalid arguments' do
      expect do
        add_polymorphic_constraints(
          'pets',
          { cat_id: 'cats.id' },
          on_update: :invalid
        )
      end.to raise_error ArgumentError
    end

    it 'truncates long trigger names to 64 characters' do
      create_table(:pets) do |t|
        t.integer long_column1
        t.integer long_column2
      end

      add_polymorphic_constraints(
        'pets',
        { long_column1 => 'cats.id', long_column2 => 'dogs.id' }
      )

      should_execute_sql <<-EOS
        DROP TRIGGER IF EXISTS pfki_pets_xxxxxxxxxxxxxxxxxxxxxxxxxx_yyyyyyyyyyyyyyyyyyyyyyyyyy
        DROP TRIGGER IF EXISTS pfku_pets_xxxxxxxxxxxxxxxxxxxxxxxxxx_yyyyyyyyyyyyyyyyyyyyyyyyyy
        CREATE TRIGGER pfki_pets_xxxxxxxxxxxxxxxxxxxxxxxxxx_yyyyyyyyyyyyyyyyyyyyyyyyyy BEFORE INSERT ON pets
          FOR EACH ROW
            BEGIN
              IF(IF(NEW.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx IS NULL, 0, 1) + IF(NEW.yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy IS NULL, 0, 1)) <> 1 THEN
                SET NEW = 'Error';
              END IF;
            END
        CREATE TRIGGER pfku_pets_xxxxxxxxxxxxxxxxxxxxxxxxxx_yyyyyyyyyyyyyyyyyyyyyyyyyy BEFORE UPDATE ON pets
          FOR EACH ROW
            BEGIN
              IF(IF(NEW.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx IS NULL, 0, 1) + IF(NEW.yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy IS NULL, 0, 1)) <> 1 THEN
                SET NEW = 'Error';
              END IF;
            END
      EOS
    end
  end

  describe '#remove_polymorphic_constraints' do
    it 'removes triggers and foreign keys with no uniqueness constraints' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        unique: true
      )
      clear_sql_history

      remove_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' }
      )
      should_execute_sql <<-EOS
        DROP TRIGGER IF EXISTS pfki_pets_catid_dogid
        DROP TRIGGER IF EXISTS pfku_pets_catid_dogid
      EOS
    end

    it 'removes uniqueness index specified with true' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        unique: true
      )
      clear_sql_history

      remove_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        unique: true
      )
      should_execute_sql <<-EOS
        DROP INDEX pfk_pets_catid ON pets
        DROP INDEX pfk_pets_dogid ON pets
      EOS
    end

    it 'removes uniqueness index specified with a string' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        unique: 'name'
      )
      clear_sql_history

      remove_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        unique: 'name'
      )

    end

    it 'removes uniqueness index specified with an array' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        unique: [:name, :color]
      )
      clear_sql_history

      remove_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        unique: [:name, :color]
      )

    end

    it 'removes an on update constraint' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        on_update: :cascade
      )
      clear_sql_history

      remove_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        on_update: :cascade
      )

    end

    it 'removes an on delete constraint' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        on_delete: :cascade
      )
      clear_sql_history

      remove_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' },
        on_update: :cascade
      )

    end

    it 'truncates long trigger names to 64 characters' do
      create_table(:pets) do |t|
        t.integer long_column1
        t.integer long_column2
      end
      add_polymorphic_constraints(
        'pets',
        { long_column1 => 'cats.id', long_column2 => 'dogs.id' }
      )
      clear_sql_history

      remove_polymorphic_constraints(
        'pets',
        { long_column1 => 'cats.id', long_column2 => 'dogs.id' }
      )
      should_execute_sql <<-EOS
        DROP TRIGGER IF EXISTS pfki_pets_xxxxxxxxxxxxxxxxxxxxxxxxxx_yyyyyyyyyyyyyyyyyyyyyyyyyy
        DROP TRIGGER IF EXISTS pfku_pets_xxxxxxxxxxxxxxxxxxxxxxxxxx_yyyyyyyyyyyyyyyyyyyyyyyyyy
      EOS
    end
  end

  describe "#triggers" do
    it 'returns the triggers for the current schema' do
      add_polymorphic_constraints(
        'pets',
        { cat_id: 'cats.id', dog_id: 'dogs.id' }
      )
      expect(triggers.map(&:name)).to eq(
        ['pfki_pets_catid_dogid', 'pfku_pets_catid_dogid']
      )
    end
  end
end
