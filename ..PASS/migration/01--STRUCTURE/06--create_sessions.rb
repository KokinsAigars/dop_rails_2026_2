# bin/rails generate migration CreateSessions
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    # Add id: :uuid if you want the session itself to have a UUID (recommended for consistency)
    create_table :sessions, id: :uuid do |t|
      # CRITICAL: 'type: :uuid' here
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.inet :ip_address
      t.text :user_agent

      t.timestamp :last_seen_at
      t.timestamp :expires_at
      t.timestamp :revoked_at

      t.timestamps
    end

    add_index :sessions, :expires_at
    add_index :sessions, :last_seen_at
    add_index :sessions, %i[user_id created_at]
  end
end
