# Sc01Abbreviations::AbbrTypographical

# frozen_string_literal: true

module Sc01Abbreviations
  class AbbrTypographical < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_01_abbreviations.abbr_typographicals"

    validates :abbr_name, presence: true
  end
end
