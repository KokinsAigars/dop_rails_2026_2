# frozen_string_literal: true

# Represents an authentication session for a {User}.
# Tracks session expiration, revocation, and basic client metadata.
#
# @!attribute [r] user_id
#   @return [String] UUID of the associated user.
# @!attribute [rw] ip_address
#   @return [String] The IP address from which the session was established.
# @!attribute [rw] user_agent
#   @return [String] The client's User-Agent string.
# @!attribute [rw] last_seen_at
#   @return [Time] The last time the session was active.
# @!attribute [rw] expires_at
#   @return [Time] When the session is scheduled to expire.
# @!attribute [rw] revoked_at
#   @return [Time, nil] When the session was manually revoked.
class Session < ApplicationRecord
  belongs_to :user, inverse_of: :sessions

  self.implicit_order_column = "created_at"

  # --- Scopes (optional but useful) ---

  # Sessions that are not revoked and have not yet expired.
  #
  # @return [ActiveRecord::Relation<Session>]
  scope :active, -> {
    where(revoked_at: nil)
      .where("expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP")
  }

  # Sessions that have reached their expiration time.
  #
  # @return [ActiveRecord::Relation<Session>]
  scope :expired, -> {
    where.not(expires_at: nil)
         .where("expires_at <= CURRENT_TIMESTAMP")
  }

  # Sessions that have been explicitly revoked.
  #
  # @return [ActiveRecord::Relation<Session>]
  scope :revoked, -> { where.not(revoked_at: nil) }
end
