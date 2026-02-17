# Sc02Bibliography::RefDoc

# frozen_string_literal: true

module Sc02Bibliography
  class RefDoc < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_02_bibliography.ref_doc"

    validates :doc_title, presence: true
  end
end
