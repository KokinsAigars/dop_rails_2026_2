# bin/rails generate migration CreateSc06DicOcr
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc06DicOcr < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS sc_06_ocr;
    SQL

    # 1) ocr_source_doc
    create_table "sc_06_ocr.ocr_source_doc", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.text   :source_kind
      t.text   :source_uri
      t.binary :source_sha256
      t.jsonb  :doc_meta, null: false, default: {}

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    # 2) ocr_page
    create_table "sc_06_ocr.ocr_page", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :fk_source_doc_id, null: false
      t.integer :page_no,          null: false

      t.binary  :page_sha256
      t.integer :image_width
      t.integer :image_height
      t.integer :dpi
      t.jsonb   :page_meta, null: false, default: {}

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    # 3) ocr_run
    create_table "sc_06_ocr.ocr_run", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.text  :engine, null: false
      t.text  :engine_version
      t.text  :lang_hint, array: true, null: false, default: []
      t.jsonb :config, null: false, default: {}

      t.timestamp :started_at,  null: false, default: -> { "now()" }
      t.timestamp :finished_at
      t.text      :status, null: false, default: "ok"
      t.text      :log

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    # 4) ocr_page_result
    create_table "sc_06_ocr.ocr_page_result", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :fk_run_id,  null: false
      t.uuid :fk_page_id, null: false

      t.text    :raw_text
      t.jsonb   :raw_json, null: false, default: {}
      t.decimal :mean_conf, precision: 5, scale: 2
      t.text    :warnings, array: true, null: false, default: []

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    # 5) ocr_token
    create_table "sc_06_ocr.ocr_token", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid    :fk_page_result_id, null: false
      t.integer :token_no,          null: false

      t.text    :text,      null: false
      t.text    :text_norm, null: false
      t.jsonb   :bbox, null: false, default: {}
      t.decimal :confidence, precision: 5, scale: 2
      t.text    :kind

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    # 6) ocr_review
    create_table "sc_06_ocr.ocr_review", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :fk_page_result_id, null: false

      t.text      :review_status, null: false, default: "pending"
      t.text      :review_note
      t.text      :approved_text
      t.timestamp :reviewed_at
      t.jsonb     :reviewed_by, null: false, default: {}

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    # 7) ocr_link
    create_table "sc_06_ocr.ocr_link", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :fk_page_result_id, null: false

      t.uuid :fk_index_id
      t.uuid :fk_entry_id

      t.text    :link_kind, null: false
      t.decimal :link_conf, precision: 5, scale: 2
      t.text    :note

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end
  end

  def down
    # drop tables first (explicit ordering), then schema
    drop_table "sc_06_ocr.ocr_link",        if_exists: true
    drop_table "sc_06_ocr.ocr_review",      if_exists: true
    drop_table "sc_06_ocr.ocr_token",       if_exists: true
    drop_table "sc_06_ocr.ocr_page_result", if_exists: true
    drop_table "sc_06_ocr.ocr_run",         if_exists: true
    drop_table "sc_06_ocr.ocr_page",        if_exists: true
    drop_table "sc_06_ocr.ocr_source_doc",  if_exists: true

    execute "DROP SCHEMA IF EXISTS sc_06_ocr CASCADE;"
  end
end
