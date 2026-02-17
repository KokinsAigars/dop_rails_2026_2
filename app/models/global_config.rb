# frozen_string_literal: true

# Manages global configuration settings for the application.
# Stores key-value pairs where keys are unique identifiers.
#
# @!attribute [rw] key
#   @return [String] Unique identifier for the configuration setting.
# @!attribute [rw] value
#   @return [String, nil] The value associated with the key.
class GlobalConfig < ApplicationRecord
  validates :key, presence: true, uniqueness: true


  # Checks if a specific configuration key is enabled.
  # A key is considered enabled if its value is "true".
  #
  # @param key_name [String, Symbol] The name of the configuration key to check.
  # @return [Boolean] true if the record doesn't exist or its value is "true"; false otherwise.
  # @example
  #   GlobalConfig.enabled?(:feature_x) #=> true
  def self.enabled?(key_name)
    # Finds the record and checks if the value is "true"
    # Default to true if the record doesn't exist yet
    config = find_by(key: key_name)
    config.nil? ? true : config.value == "true"
  end


  # Sets the value for a specific configuration key.
  # Creates the record if it doesn't exist, or updates it if it does.
  #
  # @param key_name [String, Symbol] The name of the configuration key.
  # @param value [Object] The value to set (will be converted to a string).
  # @return [Boolean] true if the update/creation was successful; false otherwise.
  def self.set(key_name, value)
    config = find_or_initialize_by(key: key_name)
    config.update(value: value.to_s)
  end
end
