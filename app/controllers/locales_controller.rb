# frozen_string_literal: true

class LocalesController < ApplicationController
  allow_unauthenticated_access only: :update

  # app/controllers/locales_controller.rb
  def update
    new_locale = params[:locale].to_s

    # Validate against your routes regex: /en|lv/
    if %w[en lv].include?(new_locale)
      session[:locale] = new_locale
    end

    # Get the path the user came from (e.g., "/en/login")
    path = URI(request.referrer || "").path rescue root_path

    # Swap the locale segment in the path string
    # This turns "/en/login" into "/lv/login"
    new_path = path.sub(%r{^/(en|lv)}, "/#{new_locale}")

    # If the path didn't have a locale yet (like just "/"), add it
    new_path = "/#{new_locale}#{new_path}" unless new_path.start_with?("/#{new_locale}")

    redirect_to new_path, allow_other_host: false
  end
end
