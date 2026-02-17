# Sc01Abbreviations::AbbrGrammaticalTerm

# frozen_string_literal: true

module Sc01Abbreviations
  class AbbrGrammaticalTerm < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_01_abbreviations.abbr_grammatical_terms"

    validates :abbr_name, presence: true
    validates :abbr_letter, length: { maximum: 1 }, allow_nil: true
  end
end
