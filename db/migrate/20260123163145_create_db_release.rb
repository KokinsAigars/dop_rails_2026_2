# bin/rails generate migration CreateDbRelease
# bin/rails db:migrate

# frozen_string_literal: true

class CreateDbRelease < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :db_release, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string   :number, null: false           # e.g. "2026.01.22_01"
      t.text     :status, null: false, default: "active"
      t.datetime :released_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.boolean  :is_current, null: false, default: true
      t.text     :git_sha
      t.text     :notes
    end

    add_index :db_release, :number, unique: true
    add_index :db_release, :released_at

    # ensure only one active/current DB release
    add_index :db_release, :is_current,
              unique: true,
              where: "is_current"

    # light sanity check for status
    execute <<~SQL
      ALTER TABLE public.db_release
        ADD CONSTRAINT chk_db_release_status
        CHECK (status IN ('active','deprecated','rolled_back','hotfix'));
    SQL
  end
end
