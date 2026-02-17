# Sc01Abbreviations::AbbrDoc

# frozen_string_literal: true

module Sc01Abbreviations
  class AbbrDoc < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_01_abbreviations.abbr_docs"

    validates :doc_title, presence: true
  end
end
