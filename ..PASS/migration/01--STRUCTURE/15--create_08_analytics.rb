# bin/rails generate migration CreateSc08Analytics
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc08Analytics < ActiveRecord::Migration[8.1]
  def up

    execute <<~SQL
      CREATE SCHEMA IF NOT EXISTS sc_08_analytics
    SQL

    create_table "sc_08_analytics.bot_attempts", id: :bigint do |t|
      t.inet :ip
      t.text :note
      t.text :user_agent
      t.timestamp :event_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end

  def down
    drop_table "sc_08_analytics.bot_attempts", if_exists: true
    execute "DROP SCHEMA IF EXISTS sc_08_analytics CASCADE;"
  end
end
