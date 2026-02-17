# frozen_string_literal: true

class CookieConsentController < ApplicationController
  # This tells Rails: "It's okay if they aren't logged in yet"
  allow_unauthenticated_access only: :index

  before_action :hide_header!
  before_action :hide_footer!

  def index
  end
end
