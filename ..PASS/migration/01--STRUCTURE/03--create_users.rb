# mise use -g ruby@3.4.7
# bin/rails generate migration CreateUsers
# bin/rails db:migrate

# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension "citext" # Case-insensitive text

    create_table :users, id: :uuid do |t|
      t.citext  :email_address,   null: false
      t.citext  :username
      t.string  :password_digest, null: false

      t.boolean :enabled, null: false, default: true

      t.string  :locale
      t.string  :timezone

      t.string  :first_name
      t.string  :last_name
      t.string  :display_name
      t.text    :bio

      t.boolean :verified
      t.timestamp :verified_at
      t.timestamp :last_sign_in_at
      t.inet      :last_sign_in_ip

      t.string  :reset_password_token
      t.timestamp :reset_password_sent_at

      t.jsonb   :settings, null: false, default: {}

      t.timestamps
    end

    add_index :users, :email_address, unique: true
    add_index :users, :username, unique: true, where: "username IS NOT NULL"
    add_index :users, :settings, using: :gin
    add_index :users, :reset_password_token
  end
end
