# Sc03Dictionary::DicSearchIndex

# frozen_string_literal: true

module Sc03Dictionary
  class DicSearchIndex < ApplicationRecord
    # Override Rails convention to use your 'indexes' table
    self.table_name = "sc_03_dictionary.dic_search_indexes"

    # Explicit Bridge to the Dic_Index
    def index_head
      Sc03Dictionary::DicIndex.find_by(id: self.fk_index_id)
    end

    def self.normalize(text)
      return "" if text.blank?

      # 1. Take only the word before the definition
      clean_text = text.to_s

      clean_text.downcase
      # 2. Map Pāḷi/Sanskrit specials
                .tr('āīūṃṇñṭḍḷščžēģķļņŗṅṁ', 'aiumnntdlsczegklnrnm')
                # 3. Replace dashes/punctuation with a SPACE (instead of nothing)
                .gsub(/[-;.,]/, ' ')
                # 4. Remove anything that isn't a letter or a space
                .gsub(/[^\p{L}\s]/, '')
                # 5. Collapse multiple spaces into one and trim ends
                .squish
    end


  end
end