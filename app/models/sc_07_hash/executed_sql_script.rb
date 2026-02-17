# Sc07Hash::ExecutedSqlScript

# frozen_string_literal: true

module Sc07Hash
  class ExecutedSqlScript < ApplicationRecord
    self.table_name = "sc_07_hash.executed_sql_scripts"

    validates :file_hash, presence: true
    validates :executed_at, presence: true
  end
end
