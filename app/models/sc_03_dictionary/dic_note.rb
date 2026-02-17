# Sc03Dictionary::DicNote

# frozen_string_literal: true

module Sc03Dictionary
  class DicNote < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate
    include EntryScopedByIndex

    self.table_name = "sc_03_dictionary.dic_note"

    attr_readonly :fk_index_id, :fk_entry_id, :root_id, :version, :created_at

    belongs_to :dic_entry,
               class_name: "Sc03Dictionary::DicEntry",
               foreign_key: :fk_entry_id,
               inverse_of: :dic_notes

    validates :fk_index_id, :fk_entry_id, presence: true
    validates :note_no, numericality: { only_integer: true, allow_nil: true }
  end
end
