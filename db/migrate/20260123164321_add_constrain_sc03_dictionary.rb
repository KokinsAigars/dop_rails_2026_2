# bin/rails generate migration AddConstrainSc03Dictionary
# bin/rails db:migrate

# frozen_string_literal: true

class AddConstrainSc03Dictionary < ActiveRecord::Migration[8.1]
  TABLES = %w[
    dic_doc
    dic_index
    dic_entry
    dic_scan
    dic_ref
    dic_eg
    dic_quote
    dic_note
  ].freeze

  def up
    # 1) backfill versioning columns (legacy data)
    TABLES.each do |t|
      execute <<~SQL
        UPDATE sc_03_dictionary.#{t}
        SET
          root_id        = id,
          version        = 1,
          is_current     = true,
          superseded_at  = NULL,
          superseded_by  = NULL
        WHERE root_id IS NULL OR version IS NULL;
      SQL
    end

    # 2) enforce NOT NULL after backfill
    TABLES.each do |t|
      change_column_null "sc_03_dictionary.#{t}", :root_id, false
      change_column_null "sc_03_dictionary.#{t}", :version, false
    end

    # 3) versioning indexes
    TABLES.each do |t|
      add_index "sc_03_dictionary.#{t}", %i[root_id version],
                unique: true,
                name: "uq_#{t}_root_version"

      add_index "sc_03_dictionary.#{t}", :root_id,
                unique: true,
                where: "is_current = true",
                name: "uq_#{t}_root_current"
    end

    # 4) dic_index indexes
    add_index "sc_03_dictionary.dic_index",
              %i[source_file source_order],
              unique: true,
              name: "uq_dic_index_source_file_order"

    add_index "sc_03_dictionary.dic_index", :homograph_uuid, name: "ix_dic_index_homograph_uuid"
    add_index "sc_03_dictionary.dic_index", :source_file,    name: "ix_dic_index_source_file"

    # 5) dic_vocab indexes (NOT versioned)
    add_index "sc_03_dictionary.dic_vocab", :term_norm, name: "ix_dic_vocab_term_norm"
    add_index "sc_03_dictionary.dic_vocab", %i[lang term_norm], name: "ix_dic_vocab_lang_term_norm"

    # 6) dic_entry domain indexes/uniqueness
    add_index "sc_03_dictionary.dic_entry",
              %i[dictionary fk_index_id lang entry_no name],
              unique: true,
              name: "uq_dic_entry_per_index"

    add_index "sc_03_dictionary.dic_entry", :fk_index_id, name: "ix_dic_entry_fk_index"
    add_index "sc_03_dictionary.dic_entry", %i[lang name], name: "ix_dic_entry_lang_name"
    add_index "sc_03_dictionary.dic_entry", :revision, name: "ix_dic_entry_revision"

    # 7) dic_scan uniqueness
    add_index "sc_03_dictionary.dic_scan",
              %i[fk_index_id scan_version],
              unique: true,
              name: "uq_dic_scan_per_index_version"

    # 8) dic_ref / eg / quote / note indexes
    add_index "sc_03_dictionary.dic_ref",   :fk_index_id, name: "ix_dic_ref_fk_index"
    add_index "sc_03_dictionary.dic_ref",   :fk_entry_id, name: "ix_dic_ref_fk_entry"
    add_index "sc_03_dictionary.dic_ref",   %i[fk_index_id fk_entry_id], name: "ix_dic_ref_index_entry"

    add_index "sc_03_dictionary.dic_eg",    :fk_entry_id, name: "ix_dic_eg_fk_entry"
    add_index "sc_03_dictionary.dic_eg",    %i[fk_index_id fk_entry_id], name: "ix_dic_eg_index_entry"

    add_index "sc_03_dictionary.dic_quote", :fk_index_id, name: "ix_dic_quote_fk_index"
    add_index "sc_03_dictionary.dic_quote", :fk_entry_id, name: "ix_dic_quote_fk_entry"
    add_index "sc_03_dictionary.dic_quote", %i[fk_index_id fk_entry_id], name: "ix_dic_quote_index_entry"

    add_index "sc_03_dictionary.dic_note",  :fk_entry_id, name: "ix_dic_note_fk_entry"
    add_index "sc_03_dictionary.dic_note",  :fk_index_id, name: "ix_dic_note_fk_index"
    add_index "sc_03_dictionary.dic_note",  %i[fk_index_id fk_entry_id], name: "ix_dic_note_index_entry"

    # 9) Foreign keys (Postgres DO blocks: idempotent / safest for rebuild cycles)

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_entry_fk_index_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_entry
          ADD CONSTRAINT tbl_dic_entry_fk_index_id_fkey
          FOREIGN KEY (fk_index_id)
          REFERENCES sc_03_dictionary.dic_index(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_scan_fk_index_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_scan
          ADD CONSTRAINT tbl_dic_scan_fk_index_id_fkey
          FOREIGN KEY (fk_index_id)
          REFERENCES sc_03_dictionary.dic_index(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_ref_fk_index_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_ref
          ADD CONSTRAINT tbl_dic_ref_fk_index_id_fkey
          FOREIGN KEY (fk_index_id)
          REFERENCES sc_03_dictionary.dic_index(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_ref_fk_entry_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_ref
          ADD CONSTRAINT tbl_dic_ref_fk_entry_id_fkey
          FOREIGN KEY (fk_entry_id)
          REFERENCES sc_03_dictionary.dic_entry(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_eg_fk_index_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_eg
          ADD CONSTRAINT tbl_dic_eg_fk_index_id_fkey
          FOREIGN KEY (fk_index_id)
          REFERENCES sc_03_dictionary.dic_index(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_eg_fk_entry_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_eg
          ADD CONSTRAINT tbl_dic_eg_fk_entry_id_fkey
          FOREIGN KEY (fk_entry_id)
          REFERENCES sc_03_dictionary.dic_entry(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_quote_fk_index_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_quote
          ADD CONSTRAINT tbl_dic_quote_fk_index_id_fkey
          FOREIGN KEY (fk_index_id)
          REFERENCES sc_03_dictionary.dic_index(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_quote_fk_entry_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_quote
          ADD CONSTRAINT tbl_dic_quote_fk_entry_id_fkey
          FOREIGN KEY (fk_entry_id)
          REFERENCES sc_03_dictionary.dic_entry(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_note_fk_index_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_note
          ADD CONSTRAINT tbl_dic_note_fk_index_id_fkey
          FOREIGN KEY (fk_index_id)
          REFERENCES sc_03_dictionary.dic_index(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL

    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'tbl_dic_note_fk_entry_id_fkey'
        ) THEN
          ALTER TABLE sc_03_dictionary.dic_note
          ADD CONSTRAINT tbl_dic_note_fk_entry_id_fkey
          FOREIGN KEY (fk_entry_id)
          REFERENCES sc_03_dictionary.dic_entry(id)
          ON DELETE CASCADE;
        END IF;
      END$$;
    SQL
  end

  def down
    # drop FKs first
    execute "ALTER TABLE sc_03_dictionary.dic_note  DROP CONSTRAINT IF EXISTS tbl_dic_note_fk_entry_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_note  DROP CONSTRAINT IF EXISTS tbl_dic_note_fk_index_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_quote DROP CONSTRAINT IF EXISTS tbl_dic_quote_fk_entry_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_quote DROP CONSTRAINT IF EXISTS tbl_dic_quote_fk_index_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_eg    DROP CONSTRAINT IF EXISTS tbl_dic_eg_fk_entry_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_eg    DROP CONSTRAINT IF EXISTS tbl_dic_eg_fk_index_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_ref   DROP CONSTRAINT IF EXISTS tbl_dic_ref_fk_entry_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_ref   DROP CONSTRAINT IF EXISTS tbl_dic_ref_fk_index_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_scan  DROP CONSTRAINT IF EXISTS tbl_dic_scan_fk_index_id_fkey;"
    execute "ALTER TABLE sc_03_dictionary.dic_entry DROP CONSTRAINT IF EXISTS tbl_dic_entry_fk_index_id_fkey;"

    # drop domain indexes by name
    remove_index "sc_03_dictionary.dic_index", name: "uq_dic_index_source_file_order"
    remove_index "sc_03_dictionary.dic_index", name: "ix_dic_index_homograph_uuid"
    remove_index "sc_03_dictionary.dic_index", name: "ix_dic_index_source_file"

    remove_index "sc_03_dictionary.dic_vocab", name: "ix_dic_vocab_term_norm"
    remove_index "sc_03_dictionary.dic_vocab", name: "ix_dic_vocab_lang_term_norm"

    remove_index "sc_03_dictionary.dic_entry", name: "uq_dic_entry_per_index"
    remove_index "sc_03_dictionary.dic_entry", name: "ix_dic_entry_fk_index"
    remove_index "sc_03_dictionary.dic_entry", name: "ix_dic_entry_lang_name"
    remove_index "sc_03_dictionary.dic_entry", name: "ix_dic_entry_revision"

    remove_index "sc_03_dictionary.dic_scan", name: "uq_dic_scan_per_index_version"

    remove_index "sc_03_dictionary.dic_ref", name: "ix_dic_ref_fk_index"
    remove_index "sc_03_dictionary.dic_ref", name: "ix_dic_ref_fk_entry"
    remove_index "sc_03_dictionary.dic_ref", name: "ix_dic_ref_index_entry"

    remove_index "sc_03_dictionary.dic_eg", name: "ix_dic_eg_fk_entry"
    remove_index "sc_03_dictionary.dic_eg", name: "ix_dic_eg_index_entry"

    remove_index "sc_03_dictionary.dic_quote", name: "ix_dic_quote_fk_index"
    remove_index "sc_03_dictionary.dic_quote", name: "ix_dic_quote_fk_entry"
    remove_index "sc_03_dictionary.dic_quote", name: "ix_dic_quote_index_entry"

    remove_index "sc_03_dictionary.dic_note", name: "ix_dic_note_fk_entry"
    remove_index "sc_03_dictionary.dic_note", name: "ix_dic_note_fk_index"
    remove_index "sc_03_dictionary.dic_note", name: "ix_dic_note_index_entry"

    # drop versioning indexes
    TABLES.each do |t|
      remove_index "sc_03_dictionary.#{t}", name: "uq_#{t}_root_version"
      remove_index "sc_03_dictionary.#{t}", name: "uq_#{t}_root_current"
    end

    # loosen NOT NULL again
    TABLES.each do |t|
      change_column_null "sc_03_dictionary.#{t}", :version, true
      change_column_null "sc_03_dictionary.#{t}", :root_id, true
    end
  end
end
