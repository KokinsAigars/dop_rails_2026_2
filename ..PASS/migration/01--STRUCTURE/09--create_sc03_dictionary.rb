# bin/rails generate migration CreateSc03Dictionary
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc03Dictionary < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS sc_03_dictionary;
    SQL

    # enum type sc_03_dictionary.dic_lang
    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1
          FROM pg_type t
          JOIN pg_namespace n ON n.oid = t.typnamespace
          WHERE t.typname = 'dic_lang'
            AND n.nspname = 'sc_03_dictionary'
        ) THEN
          CREATE TYPE sc_03_dictionary.dic_lang AS ENUM ('pi', 'en', 'lv');
        END IF;
      END
      $$;
    SQL

    create_table "sc_03_dictionary.dic_doc",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.text  :doc_title
      t.text  :doc_license
      t.jsonb :doc_reference, default: {}

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by, default: {}
    end

    create_table "sc_03_dictionary.dic_index",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.integer :dictionary, null: false, default: 1

      t.integer :entry_no
      t.text    :homograph
      t.integer :homograph_no
      t.uuid    :homograph_uuid

      t.text    :source_file,  null: false
      t.integer :source_order, null: false
      t.text    :xml_index_id

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by, default: {}
    end

    create_table "sc_03_dictionary.dic_entry",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.uuid   :fk_index_id, null: false
      t.column :lang, "sc_03_dictionary.dic_lang", null: false

      t.integer :dictionary,    null: false, default: 1
      t.integer :entry_version, null: false, default: 1

      t.integer :entry_no, null: false
      t.string  :letter, limit: 2
      t.text    :name

      t.text :name_orig
      t.text :dic_name
      t.text :dic_name_orig
      t.text :dic_eng_tr
      t.text :gender
      t.text :grammar
      t.text :etymology
      t.text :compare
      t.text :compare_sanskrit
      t.text :sanskrit
      t.text :opposite
      t.text :vedic
      t.text :note
      t.text :xref

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by, default: {}
    end

    create_table "sc_03_dictionary.dic_scan",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :fk_index_id,  null: false
      t.integer :scan_version, null: false

      t.text :scan_filename
      t.text :scan_note
      t.text :scan_text
      t.text :scan_text_raw

      t.jsonb :scan_meta
      t.text  :scan_status

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by, default: {}
    end

    create_table "sc_03_dictionary.dic_ref",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.uuid :fk_index_id, null: false
      t.uuid :fk_entry_id, null: false

      t.integer :ref_no
      t.text    :ref_note
      t.text    :ref_name
      t.text    :ref_etymology
      t.text    :ref_compare
      t.text    :ref_compare_sanskrit
      t.text    :ref_opposite
      t.text    :ref_xref

      t.uuid :bibliography_uuid

      t.text :citation_ref_src
      t.text :citation_abbrev
      t.text :citation_vol
      t.text :citation_part
      t.text :citation_p
      t.text :citation_pp
      t.text :citation_para
      t.text :citation_line
      t.text :citation_verse
      t.text :citation_char

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by, default: {}
    end

    create_table "sc_03_dictionary.dic_eg",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.uuid :fk_index_id, null: false
      t.uuid :fk_entry_id, null: false

      t.integer :eg_no
      t.text    :eg_note
      t.text    :eg_name
      t.text    :eg_etymology
      t.text    :eg_compare
      t.text    :eg_compare_sanskrit
      t.text    :eg_opposite
      t.text    :eg_xref

      t.uuid :bibliography_uuid

      t.text :citation_ref_src
      t.text :citation_abbrev
      t.text :citation_vol
      t.text :citation_part
      t.text :citation_p
      t.text :citation_pp
      t.text :citation_para
      t.text :citation_line
      t.text :citation_verse
      t.text :citation_char

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by, default: {}
    end

    create_table "sc_03_dictionary.dic_quote",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.uuid :fk_index_id, null: false
      t.uuid :fk_entry_id, null: false

      t.integer :quote_no
      t.text    :quote_note
      t.text    :quote_name
      t.text    :quote_etymology
      t.text    :quote_compare
      t.text    :quote_compare_sanskrit
      t.text    :quote_opposite
      t.text    :quote_xref

      t.uuid :bibliography_uuid

      t.text :citation_ref_src
      t.text :citation_abbrev
      t.text :citation_vol
      t.text :citation_part
      t.text :citation_p
      t.text :citation_pp
      t.text :citation_para
      t.text :citation_line
      t.text :citation_verse
      t.text :citation_char

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by, default: {}
    end

    create_table "sc_03_dictionary.dic_note",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.uuid :fk_index_id, null: false
      t.uuid :fk_entry_id, null: false

      t.integer :note_no
      t.text    :note_note

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by, default: {}
    end
  end
end
