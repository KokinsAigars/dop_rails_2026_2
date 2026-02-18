# Standard B-Tree indexes in Postgres don't handle ILIKE with wildcards well. For your DicVocab table, you should add a GIN index with the pg_trgm extension.
#  Adding the possibility to search 10 queries per second, The GIN Trigram index breaks your words into 3-character chunks
# GIN Trigram index indexes every 3-letter combination. When you search for baddha, it quickly finds the bad, add, ddh, and dha chunks inside a-baddha.

# frozen_string_literal: true

class AddTrgmIndexToVocab < ActiveRecord::Migration[8.0]
  def change
    # It is usually safest to install extensions in public
    # so all schemas can access them
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    # Use the full schema-qualified table name
    table_name = '"sc_03_dictionary"."dic_vocab"'

    add_index table_name, :term_norm,
              name: 'idx_dic_vocab_term_norm_trgm', # Explicit name is better for long schema names
              using: :gin,
              opclass: :gin_trgm_ops

    add_index table_name, :term,
              name: 'idx_dic_vocab_term_trgm',
              using: :gin,
              opclass: :gin_trgm_ops
  end
end