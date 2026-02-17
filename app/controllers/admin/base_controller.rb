# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController

    before_action :require_authentication
    before_action :load_explorer_users
    # Custom check for the role
    before_action :ensure_admin!
    before_action :set_current_authenticated_user

    layout :determine_layout

    def render_workspace(title:, explorer_partial:, edit_partial:, locals: {})
      render json: {
        explorer_title: title,
        explorer_html:  render_to_string(partial: explorer_partial, locals: locals, formats: [:html]),
        edit_html:      render_to_string(partial: edit_partial, locals: locals, formats: [:html])
      }
    end

    private

    def ensure_admin!
      # If Current.user is nil or not an admin, boot them
      unless Current.user&.admin?
        redirect_to root_path, alert: "Access denied: Admins only."
      end
    end

    def set_current_authenticated_user
      # This logic is usually generated in app/controllers/concerns/authentication.rb
      # It ensures Current.user is actually filled with data
      resume_session
    end

    def load_explorer_users
      @explorer_users = User.limit(20)
      @apps = Doorkeeper::Application.all # Or however your OAuth model is named
    end

    def determine_layout
      # If the request is AJAX (from Stimulus), we don't need a layout at all
      return false if request.xhr?

      # Otherwise, use the workspace shell
      "user_workspace"
    end


  end
end
