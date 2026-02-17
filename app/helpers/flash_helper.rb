# frozen_string_literal: true

# This is a View Helper. It contains logic for making HTML/CSS look pretty.
# Do not include it in Controllers that talk to the Database and Session.
# Helpers talk to the Browser and HTML.
module FlashHelper
  def flashHelper_class(type) # Renamed for clarity
    case type.to_sym
    when :notice, :success then "flash-success"
    when :alert, :error   then "flash-alert"
    when :info            then "flash-info"
    when :warning         then "flash-warning"
    else "flash-#{type}"
    end
  end
end
