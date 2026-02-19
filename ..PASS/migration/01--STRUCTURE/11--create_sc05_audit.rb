# bin/rails generate migration CreateSc05DicAudit
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc05DicAudit < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS sc_05_audit;
    SQL

    create_table "sc_05_audit.abbr_audit_events",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.timestamp :event_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.text      :action, null: false
      t.text      :table_name, null: false
      t.uuid      :row_id, null: false

      t.uuid    :root_id
      t.integer :version

      t.text :session_id
      t.uuid :user_id
      t.uuid :oauth_application_id
      t.text :request_id
      t.inet :ip
      t.text :user_agent

      t.text  :reason
      t.jsonb :diff
      t.jsonb :snapshot
    end

    create_table "sc_05_audit.ref_audit_events",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.timestamp :event_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.text      :action, null: false
      t.text      :table_name, null: false
      t.uuid      :row_id, null: false

      t.uuid    :root_id
      t.integer :version

      t.text :session_id
      t.uuid :user_id
      t.uuid :oauth_application_id
      t.text :request_id
      t.inet :ip
      t.text :user_agent

      t.text  :reason
      t.jsonb :diff
      t.jsonb :snapshot
    end

    create_table "sc_05_audit.dic_entry_audit_events",
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.timestamp :event_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.text      :action, null: false
      t.text      :table_name, null: false
      t.uuid      :row_id, null: false

      t.uuid    :root_id
      t.integer :version

      t.text :session_id
      t.uuid :user_id
      t.uuid :oauth_application_id
      t.text :request_id
      t.inet :ip
      t.text :user_agent

      t.text  :reason
      t.jsonb :diff
      t.jsonb :snapshot
    end
  end

  def down
    drop_table "sc_05_audit.dic_entry_audit_events", if_exists: true
    drop_table "sc_05_audit.ref_audit_events",       if_exists: true
    drop_table "sc_05_audit.abbr_audit_events",      if_exists: true
    execute "DROP SCHEMA IF EXISTS sc_05_audit CASCADE;"
  end
end

