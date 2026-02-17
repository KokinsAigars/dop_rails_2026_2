# frozen_string_literal: true

module Admin
  module Management
    class SystemController < Admin::BaseController

      include HasUiSettings


      def trigger_flash
        case params[:type]
        when "alert"
          notify("Bot Intercepted from IP: #{request.remote_ip}", :alert)
        when "success"
          notify("System synchronization complete.", :notice)
        when "info"
          notify("New Ghost Protocol log available.", :info)
        end

        # Redirect back to where you came from
        redirect_back fallback_location: admin_root_path
      end
    end
  end
end
