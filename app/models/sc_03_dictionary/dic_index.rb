# Sc03Dictionary::DicIndex

# frozen_string_literal: true

module Sc03Dictionary
  class DicIndex < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_03_dictionary.dic_index"

    validates :dictionary, :source_file, :source_order, presence: true

    # This creates 'ghost' methods for the top-level keys
    store_accessor :modified_by, :actor, :change, :source

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
             dependent: :destroy,
             primary_key: :id # Or :uuid

    # You can even create helper methods for deep keys
    def editor_name
      actor&.fetch("fullname", "Unknown")
    end

    def change_ticket
      change&.fetch("ticket", "N/A")
    end

  end
end

# :modified_by
#
# {
#   "actor": {
#     "type": "user",
#     "user_id": "019b99cf-0ae8-7b12-b90f-6eb587f47655",
#     "fullname": "Aigars Kokins"
#   },
#   "change": {
#     "reason": "db insert",
#     "ticket": "RIX-2026.01.07-01"
#   },
#   "source": {
#     "app": "python-script",
#     "client": "postgresql"
#   }
# }
#
