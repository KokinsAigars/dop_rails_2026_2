# bin/rails generate migration CreateSc07Hash
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc07Hash < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS sc_07_hash;
    SQL

    # Rails default id: bigint (good). Keep it.
    create_table "sc_07_hash.temporary_hash", id: false do |t|
      t.binary :dic_index_hash, null: false
      t.uuid   :fk_index_id,    null: false
    end

    create_table "sc_07_hash.executed_sql_scripts" do |t|
      t.text      :file_hash,   null: false
      t.text      :file_path
      t.timestamp :executed_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end

  def down
    drop_table "sc_07_hash.executed_sql_scripts", if_exists: true
    drop_table "sc_07_hash.temporary_hash",      if_exists: true
    execute "DROP SCHEMA IF EXISTS sc_07_hash CASCADE;"
  end
end
