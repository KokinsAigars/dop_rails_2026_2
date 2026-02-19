# bin/rails generate migration CreateSc03DicSearchIndex
# bin/rails db:migrate

# frozen_string_literal: true

class CreateSc03DicSearchIndex < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    table_full_name = "sc_03_dictionary.dic_search_indexes"

    create_table table_full_name, id: false do |t| # id: false since we don't need a primary key
      t.string  :term, null: false
      t.string  :term_norm, null: false
      t.string  :lang, limit: 10
      t.uuid    :fk_index_id, null: false
    end

    # 1. Trigram Index on term_norm
    add_index table_full_name, :term_norm,
              name: 'idx_dic_search_term_norm_trgm',
              using: :gin,
              opclass: :gin_trgm_ops

    # 2. Trigram Index on term
    add_index table_full_name, :term,
              name: 'idx_dic_search_term_trgm',
              using: :gin,
              opclass: :gin_trgm_ops

    # 3. The "Bouncer" - Unique Index
    # This prevents the exact same term/lang/id combo from ever repeating
    add_index table_full_name, [:term, :lang, :fk_index_id],
              unique: true,
              name: 'idx_unique_search_entry'

    add_index table_full_name, :fk_index_id, name: 'idx_dic_search_fk_index'
  end
end
