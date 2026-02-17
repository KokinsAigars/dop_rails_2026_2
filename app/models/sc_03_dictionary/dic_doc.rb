# Sc03Dictionary::DicDoc

# frozen_string_literal: true

module Sc03Dictionary
  class DicDoc < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_03_dictionary.dic_doc"

    validates :doc_title, presence: true
  end
end
