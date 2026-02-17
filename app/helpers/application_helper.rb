# frozen_string_literal: true

module ApplicationHelper
  # Helpers are modules whose methods are automatically available in views.
  def format_username(user)
    "#{user.first_name} #{user.last_name}".strip
  end
  # in view <%= format_username(@user) %>

end
