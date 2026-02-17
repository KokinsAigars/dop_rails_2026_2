# frozen_string_literal: true

class Api::V1::PingController < Api::V1::BaseController
    before_action -> { doorkeeper_authorize! :admin }

    def show
      render json: {
        ok: true,
        app: current_oauth_application&.name,
        token_scopes: doorkeeper_token&.scopes&.to_s
      }
    end
end
