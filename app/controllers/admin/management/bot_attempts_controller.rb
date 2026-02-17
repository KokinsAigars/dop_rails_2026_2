# frozen_string_literal: true

module Admin
  module Management
    class BotAttemptsController < Admin::BaseController
      def index
        @bot_attempts = Sc08Analytics::BotAttempt.order(event_at: :desc).limit(10)
      end
    end
  end
end
