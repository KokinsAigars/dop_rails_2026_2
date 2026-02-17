# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController

    # render json: {
    #   explorer_html: render_to_string(partial: "explorer"),
    #   edit_html:     render_to_string(partial: "dashboard_overview")
    # }

    def show
      if request.xhr?
        # Render without the 'workspace' layout so we just get the inner HTML
        render partial: "dashboard_content", layout: false
      else
        # Standard page load
        render :show
      end
    end

    #
    # def show
    #
    #   # Landing page for Admins
    #   @stats = GlobalConfig.count
    #
    #   #
    #   # @total_users = User.count
    #   # @recent_bots = Sc08Analytics::BotAttempt.order(event_at: :desc).limit(10)
    #   # @bot_count_24h = Sc08Analytics::BotAttempt.where("event_at > ?", 24.hours.ago).count
    #   #
    #   # # For a small sparkline/graph later
    #   # @daily_stats = Sc08Analytics::BotAttempt.where("event_at > ?", 7.days.ago)
    # end

    # def test_flash
    #   # render plain: "User: #{Current.user.inspect}, Admin: #{Current.user.inspect}"
    #   #
    #   # # We pass the user in a hash (options) so notify doesn't crash
    #   # notify("Testing success", :success, user: Current.user)
    #   #
    #   # redirect_to admin_root_path
    #   #
    #
    #   case params[:type]
    #   when "alert"
    #     notify("Bot Intercepted from IP: 192.168.1.1", :alert)
    #   when "success"
    #     notify("Workspace configurations saved successfully.", :success)
    #   when "notice"
    #     notify("my notice message", :notice)
    #   when "info"
    #     notify("info info info message", :info)
    #   when "warning"
    #     notify("Some warning as flash message", :warning)
    #   else
    #     return
    #   end
    #
    #   redirect_to admin_root_path
    # end
    #
    # def load_explorer_users
    #   @explorer_users = User.limit(20)
    #   @apps = Doorkeeper::Application.all # Or however your OAuth model is named
    # end
  end
end
