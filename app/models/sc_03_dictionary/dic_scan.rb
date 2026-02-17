# Sc03Dictionary::DicScan

# frozen_string_literal: true

module Sc03Dictionary
  class DicScan < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_03_dictionary.dic_scan"

    validates :scan_version,
              uniqueness: {
                scope: [ :fk_index_id, :is_current ],
                message: "scan version already exists for this index"
              }

    validates :scan_text_raw, presence: true

    belongs_to :dic_index,
               class_name: "Sc03Dictionary::DicIndex",
               foreign_key: :fk_index_id,
               inverse_of: :dic_scans
  end
end
