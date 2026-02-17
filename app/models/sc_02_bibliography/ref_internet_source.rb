# Sc02Bibliography::RefInternetSource

# frozen_string_literal: true

module Sc02Bibliography
  class RefInternetSource < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    self.table_name = "sc_02_bibliography.ref_internet_sources"

    validates :ref_url, presence: true
  end
end
