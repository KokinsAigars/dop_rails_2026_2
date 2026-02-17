# frozen_string_literal: true

# Represents a user in the system.
# Handles authentication, role-based access control, and UI preferences.
#
# @!attribute [rw] email_address
#   @return [String] Unique identifier; used for login and normalized to lowercase.
# @!attribute [rw] display_name
#   @return [String, nil] The name shown in the UI (Activity Bar/Explorer).
# @!attribute [rw] settings
#   @return [Hash] JSONB store for preferences (UI theme, notifications, etc.).
class User < ApplicationRecord
  # Debugging logs. test function calls in the console
  # Includes {GhostTraceable} for advanced system debugging.
  include GhostTraceable

  # DB column: password_digest
  has_secure_password

  # --- Associations ---
  has_many :sessions, dependent: :destroy

  has_many :user_roles, inverse_of: :user, dependent: :destroy
  has_many :roles, through: :user_roles

  # ActiveStorage (requires active_storage tables + storage service)
  has_one_attached :avatar

  # --- Scopes ---
  scope :enabled,  -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  # --- Normalization ---
  before_validation :private_normalize_email

  # --- Validations ---
  validates :email_address,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email address" }

  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :password, confirmation: true, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? }
  validates :locale, inclusion: { in: %w[en lv] }, allow_nil: true
  validates :username, uniqueness: { allow_nil: true, case_sensitive: false }
  validate :private_settings_must_be_valid_json

  after_initialize :private_set_defaults, if: :new_record?
  after_initialize :private_set_default_settings, if: :new_record?

  before_save :private_set_display_name, if: -> { display_name.blank? }

  # Ensure JSONB defaults are handled at the model level too
  attribute :settings, :jsonb, default: {}


  # --- Role helpers ---

  # Checks if the user has a specific role assigned.
  #
  # @param name [String, Symbol] The name of the role (e.g., :admin, :user)
  # @return [Boolean] True if the role exists for this user.
  def has_role?(name)
    roles.exists?(name: name.to_s)
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

    @admin_result
  end


  # --- Display helpers ---

  # Combines first and last name into a single string.
  #
  # @return [String] The full name or an empty string if neither is set.
  # @example
  #   user.full_name #=> "John Doe"
  def full_name
    ([ first_name, last_name ].compact.join(" ").strip).to_s
  end

  # Returns the best available name for UI display.
  # Priority: display_name > full_name > email_address.
  #
  # @return [String]
  def label
    (display_name.presence || full_name.presence || email_address).to_s
  end


  # --- Settings helpers ---

  # Retrieves the 'ui' sub-hash from the settings JSONB column.
  # Useful for retrieving theme preferences, sidebar widths, etc.
  #
  # @return [Hash] The UI settings or an empty hash.
  def ui_settings
    settings.fetch("ui", {}).to_h
  end

  # Updates a specific UI setting and persists it to the database immediately.
  #
  # @param key [String, Symbol] The setting name (e.g., :sidebar_width).
  # @param value [Object] The value to store (must be JSON-serializable).
  # @return [Boolean] Whether the update was successful.
  def set_ui!(key, value)
    # 1. Start with a fresh copy to ensure Rails tracks the change
    new_settings = settings.deep_dup

    # 2. Ensure the nested structure exists
    new_settings["ui"] ||= {}

    # 3. Cast the key to a string (JSONB keys are always strings)
    new_settings["ui"][key.to_s] = value

    # 4. Use update_column if you want to skip validations/callbacks for speed,
    # or update! if you want the full Rails lifecycle.
    result = update(settings: new_settings) # returns true/false
    private_ghost_trace("UI Save: #{key}", trace: false)
    private_ghost_trace("UI Preference Saved: #{key} => #{value}", trace: false)

    result

  end

  # Checks if the user's email has been verified.
  #
  # @return [Boolean]
  def verified?
    verified && verified_at.present?
  end

  # Marks the user as verified and records the current timestamp.
  #
  # @return [Boolean]
  def verify!
    update!(verified_at: Time.current, verified: true)
  end

  # Generates a SecureRandom token for password resets.
  # Sets reset_password_token and reset_password_sent_at.
  #
  # @return [String] The raw token to be sent via email.
  def generate_password_reset_token
    token = SecureRandom.urlsafe_base64
    update(reset_password_token: token, reset_password_sent_at: Time.current)
    token
  end

  # Checks if a specific notification type is enabled in the user's settings.
  # Defaults to true unless explicitly set to false.
  #
  # @param type [String, Symbol] The notification category (e.g., :marketing, :security).
  # @return [Boolean]
  def notification_enabled?(type)
    data = (settings || {}).dig("notifications", type.to_s)
    !(data == false || data == "false")
  end


  private

  # Generates a display_name from names or email before saving.
  # @return [void]
  def private_set_display_name
    self.display_name = "#{first_name} #{last_name}".strip
    self.display_name = email_address.split("@").first if display_name.blank?
  end

  # Validation to ensure the JSONB column remains a Hash.
  # @return [void]
  def private_settings_must_be_valid_json
    unless settings.is_a?(Hash)
      errors.add(:settings, "must be a valid JSON object")
    end
  end

  # Sanitizes the email address by trimming whitespace and downcasing.
  # @return [void]
  def private_normalize_email
    self.email_address = email_address.to_s.strip.downcase.presence
  end

  # Sets initial state for new records (enabled = true, locale = en).
  # @return [void]
  def private_set_defaults
    self.enabled = true if self.enabled.nil?
    self.locale ||= "en"
  end


  def set_default_settings
    self.settings ||= {
      "ui" => {
        "layout" => "right",
        "explorer_width" => 300,
        "theme" => "dark"
      }
    }
  end

end
