# bin/rails generate migration CreateRoles
# bin/rails db:migrate

# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :label        # e.g. "Administrator"
      t.text   :description  # what this role is for
      t.timestamps
    end

    add_index :roles, "lower(name)", unique: true, name: "uq_roles_lower_name"
  end
end
