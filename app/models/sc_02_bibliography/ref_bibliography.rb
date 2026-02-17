# Sc02Bibliography::RefBibliography

# frozen_string_literal: true

module Sc02Bibliography
  class RefBibliography < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_02_bibliography.ref_bibliography"

    validates :ref_title, presence: true
  end
end
