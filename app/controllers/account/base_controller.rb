# frozen_string_literal: true

module Account
  class BaseController < ApplicationController

    before_action :require_authentication

    layout :determine_layout

    def render_workspace(title:, explorer_partial:, edit_partial:, locals: {})
      render json: {
        explorer_title: title,
        explorer_html:  render_to_string(partial: explorer_partial, locals: locals, formats: [:html]),
        edit_html:      render_to_string(partial: edit_partial, locals: locals, formats: [:html])
      }
    end


    private

    def determine_layout
      # If the request is AJAX (from Stimulus), we don't need a layout at all
      return false if request.xhr?

      # Otherwise, use the workspace shell
      "user_workspace"
    end

  end
end
