# bin/rails generate migration CreateGlobalConfigs
# bin/rails db:migrate

# frozen_string_literal: true

class CreateGlobalConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :global_configs do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
    add_index :global_configs, :key, unique: true
  end
end


