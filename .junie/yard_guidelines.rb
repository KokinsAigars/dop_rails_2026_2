# frozen_string_literal: true

# YARD documentation style guideline example.
#
# This file demonstrates preferred YARD tags and formatting used in this project.
# It lives under `.junie/` and is not part of the application runtime.
module YARDGuidelines
  # Represents a user in the system.
  # Handles authentication, role-based access control, and UI preferences.
  #
  # @!attribute [r] email_address
  #   @return [String] Unique identifier for the user.
  # @!attribute [rw] display_name
  #   @return [String] The name shown in the UI (Activity Bar/Explorer).
  # @!attribute [rw] settings
  #   @return [Hash] JSON-like hash for user preferences and notifications.
  class User
    attr_reader :email_address
    attr_accessor :display_name, :settings, :first_name, :last_name, :roles

    # Builds a new example user instance.
    #
    # @param email_address [String] Unique user email.
    # @param display_name [String, nil] Optional UI label.
    # @param settings [Hash] Initial settings (JSON-serializable values only).
    def initialize(email_address:, display_name: nil, settings: {})
      @email_address = email_address
      @display_name = display_name
      @settings = settings
      @first_name = nil
      @last_name = nil
      @roles = []
      @admin_result = nil
    end

    # Updates a specific UI setting and persists it (example).
    #
    # @param key [String, Symbol] The setting name (e.g., :sidebar_width).
    # @param value [Object] The value to store (must be JSON-serializable).
    # @return [Boolean] Whether the update was successful.
    # @example
    #   user.set_ui!(:sidebar_width, 280) #=> true
    def set_ui!(key, value)
      new_settings = settings.dup
      new_settings["ui"] ||= {}
      new_settings["ui"][key.to_s] = value
      self.settings = new_settings
      true
    end

    # Combines first and last name into a single string.
    #
    # @return [String] The full name or an empty string if neither is set.
    # @example
    #   user.full_name #=> "John Doe"
    def full_name
      [first_name, last_name].compact.join(" ").strip.to_s
    end

    # Checks if the user has administrative privileges.
    #
    # @note This method is memoized per instance during the object's lifetime.
    # @return [Boolean] true if the user has an assigned 'admin' role.
    def admin?
      @admin_result = roles.include?("admin") if @admin_result.nil?
      @admin_result
    end

    private

    # Example of a private helper with YARD docs.
    #
    # @return [void]
    def example_private_helper
      # no-op
    end
  end
end

