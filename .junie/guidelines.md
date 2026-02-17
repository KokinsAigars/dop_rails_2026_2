

# frozen_string_literal: true

# Represents a user in the system.
# Handles authentication, role-based access control, and UI preferences.
#
# @attr [String] email_address Unique identifier for the user.
# @attr [String] display_name The name is shown in the UI (Activity Bar/Explorer).
# @attr [Hash] settings JSONB stores for user-specific preferences and notifications.
class User < ApplicationRecord

# Updates a specific UI setting and persists it to the database immediately.
#
# @param key [String, Symbol] The setting name (e.g., :sidebar_width).
# @param value [Object] The value to store (must be JSON-serializable).
# @return [Boolean] Whether the update was successful.
def set_ui!(key, value)
new_settings = settings.deep_dup
new_settings["ui"] ||= {}
new_settings["ui"][key.to_s] = value
update!(settings: new_settings)
end

# Combines first and last name into a single string.
#
# @return [String] The full name or an empty string if neither is set.
# @example
#   user.full_name #=> "John Doe"
def full_name
return ([first_name, last_name].compact.join(" ").strip).to_s
end

# Specifically, checks if the user has administrative privileges.
#
# @note This method is memoized. It will only query the database once
#   per object instance during the request lifecycle.
#
# @return [Boolean] true if the user has an assigned 'admin' role.
def admin?
# 1. This always runs
puts "!!!! >>> I AM INSIDE THE ADMIN? METHOD <<< !!!!"

# 2. This only runs if we HAVEN'T checked the DB yet
if @admin_result.nil?
private_ghost_trace("Checking Database for Admin Role")
@admin_result = roles.where(name: "admin").exists?
else
# 3. This runs if we are using the cache
private_ghost_trace("Using CACHED result: #{@admin_result}", trace: false)
end

return @admin_result
end


