# Sc01Abbreviations::AbbrPublicationSource

# frozen_string_literal: true

module Sc01Abbreviations
  class AbbrPublicationSource < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_01_abbreviations.abbr_publication_sources"

    validates :abbr_name, presence: true
  end
end
