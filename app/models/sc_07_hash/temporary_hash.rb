# Sc07Hash::TemporaryHash

# frozen_string_literal: true

module Sc07Hash
  class TemporaryHash < ApplicationRecord
    self.table_name = "sc_07_hash.temporary_hash"

    validates :dic_index_hash, presence: true
    validates :fk_index_id, presence: true
  end
end
