# bin/rails generate migration CreateSc01Abbreviations
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc01Abbreviations < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS sc_01_abbreviations;
    SQL

    create_table "sc_01_abbreviations.abbr_books_periodicals", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string  :abbr_letter, limit: 1
      t.text    :abbr_name, null: false

      t.text    :abbr_id_est
      t.text    :abbr_lv
      t.text    :abbr_number
      t.uuid    :abbr_ref_id
      t.text    :abbr_note
      t.text    :abbr_source
      t.text    :abbr_source_text
      t.text    :abbr_citation
      t.text    :abbr_citation_transl
      t.text    :abbr_citation_2
      t.text    :abbr_citation_method
      t.text    :abbr_citation_method_2

      # Versioning / history
      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      # Audit metadata
      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_01_abbreviations.abbr_general_terms", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :abbr_letter, limit: 1
      t.text   :abbr_name, null: false

      t.text   :abbr_id_est
      t.text   :abbr_lv
      t.text   :abbr_ref_id
      t.text   :abbr_note
      t.text   :abbr_source
      t.text   :abbr_source_text

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_01_abbreviations.abbr_grammatical_terms", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :abbr_letter, limit: 1
      t.text   :abbr_name, null: false

      t.text   :abbr_id_est
      t.text   :abbr_lv
      t.text   :abbr_ref_id
      t.text   :abbr_source_text

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_01_abbreviations.abbr_publication_sources", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.text :abbr_name, null: false

      t.text :abbr_id_est
      t.text :abbr_note
      t.text :abbr_source_text
      t.text :abbr_citation

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_01_abbreviations.abbr_typographicals", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.text :abbr_name, null: false

      t.text :abbr_id_est
      t.uuid :abbr_ref_id

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_01_abbreviations.abbr_docs", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.text  :doc_title
      t.text  :doc_license
      t.jsonb :doc_reference

      t.boolean  :revision, null: false, default: false
      t.text     :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end
  end
end
