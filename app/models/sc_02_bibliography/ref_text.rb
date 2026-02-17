# Sc02Bibliography::RefText

# frozen_string_literal: true

module Sc02Bibliography
  class RefText < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_02_bibliography.ref_texts"

    validates :ref_texts_title, presence: true
  end
end
