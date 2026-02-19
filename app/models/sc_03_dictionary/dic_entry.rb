# frozen_string_literal: true

module Sc03Dictionary
  # Represents a primary dictionary entry within the {Sc03Dictionary} module.
  # Acts as the central anchor for references, notes, quotes, and examples.
  #
  # @!attribute [rw] lang
  #   @return [String] The ISO language code for the entry.
  # @!attribute [rw] dictionary
  #   @return [String] The name/identifier of the parent dictionary.
  # @!attribute [rw] fk_index_id
  #   @return [Integer] Foreign key to the parent {DicIndex}.
  class DicEntry < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_03_dictionary.dic_entry"

    validates :lang, :dictionary, :entry_version, :entry_no, presence: true

    # Rails creates a method dic_index()
    belongs_to :dic_index,
               class_name: "Sc03Dictionary::DicIndex",
               foreign_key: :fk_index_id,
               inverse_of: :dic_entries

    has_many :dic_refs,
             class_name: "Sc03Dictionary::DicRef",
             foreign_key: :fk_entry_id,
             inverse_of: :dic_entry,
             dependent: :destroy

    has_many :dic_notes,
             class_name: "Sc03Dictionary::DicNote",
             foreign_key: :fk_entry_id,
             inverse_of: :dic_entry,
             dependent: :destroy

    has_many :dic_quotes,
             class_name: "Sc03Dictionary::DicQuote",
             foreign_key: :fk_entry_id,
             inverse_of: :dic_entry,
             dependent: :destroy

    has_many :dic_egs,
             class_name: "Sc03Dictionary::DicEg",
             foreign_key: :fk_entry_id,
             inverse_of: :dic_entry,
             dependent: :destroy
  end
end
