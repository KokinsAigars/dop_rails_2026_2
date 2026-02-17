# bin/rails generate migration CreateSc04Language
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc04Language < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS sc_04_language;
    SQL

    create_table "sc_04_language.lang_language", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.text :lang_title
      t.text :lang_language
      t.text :lang_eng_equivalent
      t.text :lang_abbr
      t.text :lang_abbr2
      t.text :lang_url
      t.text :lang_alphabet
      t.text :lang_vowels
      t.text :lang_consonants
      t.text :lang_niggahita
      t.text :lang_code
      t.text :lang_code2

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end

    create_table "sc_04_language.lang_doc", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.text  :doc_title
      t.text  :doc_license
      t.jsonb :doc_reference

      t.boolean :revision, null: false, default: false
      t.text    :revision_comment

      t.timestamp :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamp :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb     :modified_by
    end
  end

  def down
    drop_table "sc_04_language.lang_doc",      if_exists: true
    drop_table "sc_04_language.lang_language", if_exists: true
    execute "DROP SCHEMA IF EXISTS sc_04_language CASCADE;"
  end
end
