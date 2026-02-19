# Sc03Dictionary::DicVocab

# frozen_string_literal: true

module Sc03Dictionary
  class DicVocab < ApplicationRecord
    self.table_name = "sc_03_dictionary.dic_vocab"

    self.primary_key = nil

    def self.normalize(text)
      return "" if text.blank?
      text.to_s.downcase
          .tr('āīūṃṇñṭḍḷščžēģķļņŗ', 'aiumnntdlsczegklnr') # Transliterate specific characters
          .gsub(/[-;.,]/, '')   # Specific elimination of dash, semicolon, etc.
          .gsub(/[^\p{L}\s]/, '') # Final safety: remove anything that isn't a letter or space
          .squish               # Remove double spaces if any were created
    end

  end
end
