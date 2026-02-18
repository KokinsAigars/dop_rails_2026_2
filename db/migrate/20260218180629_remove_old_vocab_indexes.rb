# bin/rails generate migration RemoveOldVocabIndexes
# bin/rails db:migrate

# frozen_string_literal: true

class RemoveOldVocabIndexes < ActiveRecord::Migration[8.0]
  def change
    table_name = '"sc_03_dictionary"."dic_vocab"'

    # Remove the standard B-Tree indexes
    remove_index table_name, name: 'ix_dic_vocab_lang_term_norm'
    remove_index table_name, name: 'ix_dic_vocab_term_norm'
  end
end


