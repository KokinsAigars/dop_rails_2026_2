# Sc03Dictionary::DicIndex

# frozen_string_literal: true

module Sc03Dictionary
  class DicIndex < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_03_dictionary.dic_index"

    validates :dictionary, :source_file, :source_order, presence: true

    has_many :dic_entries,
             class_name: "Sc03Dictionary::DicEntry",
             foreign_key: :fk_index_id,
             inverse_of: :dic_index,
             dependent: :destroy

    has_many :dic_scans,
             class_name: "Sc03Dictionary::DicScan",
             # dic_scans.fk_index_id = dic_indexes.id
             foreign_key: :fk_index_id,
             inverse_of: :dic_index,
             dependent: :destroy
  end
end
