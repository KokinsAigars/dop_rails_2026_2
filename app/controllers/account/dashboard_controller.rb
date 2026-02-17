# frozen_string_literal: true

module Account
  class DashboardController < Account::BaseController
    # Ensure they are logged in using Rails 8 helper
    before_action :require_authentication

    def show
      if request.xhr?
        # Render without the 'workspace' layout so we just get the inner HTML
        render layout: false
      else
        # Standard page load
        render :show
      end
    end
    #
    # def show
    #   # This is the landing page for regular users
    #   #
    #   # Landing page for regular Users
    #   # @recent_sessions = current_user.sessions.limit(5)
    # end
  end
end
