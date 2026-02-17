# Sc08Analytics::BotAttempt

# frozen_string_literal: true

module Sc08Analytics
  class BotAttempt < ApplicationRecord
    self.table_name = "sc_08_analytics.bot_attempts"

    validates :ip, presence: true
    validates :note, presence: true
  end
end
