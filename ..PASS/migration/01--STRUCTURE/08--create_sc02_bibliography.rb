# bin/rails generate migration CreateSc02Bibliography
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc02Bibliography < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS sc_02_bibliography;
    SQL

    create_table "sc_02_bibliography.ref_bibliography",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|

      t.text :ref_letter
      t.text :ref_abbrev

      t.text :ref_title
      t.text :ref_note
      t.text :ref_citation
      t.text :ref_footnote
      t.text :ref_publisher
      t.text :ref_place
      t.text :ref_volume
      t.text :ref_part
      t.text :ref_type
      t.text :ref_author
      t.text :ref_url
      t.text :ref_ref1
      t.text :ref_ref2
      t.text :ref_title_lv

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      # versioning (nullable for legacy restore; enforced later)
      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_02_bibliography.ref_internet_sources",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|

      t.text :ref_title
      t.text :ref_url

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_02_bibliography.ref_texts",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|

      t.text :ref_texts_no
      t.text :ref_texts_title
      t.text :ref_texts_lang

      t.text :ref_no
      t.text :ref_abbrev
      t.text :ref_title
      t.text :ref_note

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.uuid     :root_id
      t.integer  :version
      t.boolean  :is_current, null: false, default: true
      t.datetime :superseded_at
      t.uuid     :superseded_by

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_02_bibliography.ref_doc",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|

      t.text  :doc_title
      t.text  :doc_license
      t.jsonb :doc_reference

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

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
