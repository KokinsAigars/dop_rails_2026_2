# frozen_string_literal: true

# Represents a database release version and its status.
# Tracks the deployment history of database schema changes.
#
# @!attribute [r] number
#   @return [String] Unique release identifier (e.g., "2026.01.22_01").
# @!attribute [rw] status
#   @return [String] Current state: active, deprecated, rolled_back, or hotfix.
# @!attribute [r] released_at
#   @return [DateTime] When the release was applied to this environment.
# @!attribute [rw] is_current
#   @return [Boolean] true if this is the active database version.
# @!attribute [r] git_sha
#   @return [String] Associated Git commit hash for the release.
class DbRelease < ApplicationRecord
  self.table_name = "db_release"

  # List of valid release statuses.
  STATUSES = %w[active deprecated rolled_back hotfix].freeze

  before_validation :normalize_number

  validates :number, presence: true, uniqueness: { case_sensitive: false }
  validates :status, inclusion: { in: STATUSES }
  validates :released_at, presence: true

  # Returns the currently active database release.
  scope :current, -> { where(is_current: true) }

  # Orders releases by their release date descending.
  scope :latest,  -> { order(released_at: :desc) }

  private

  # Sanitizes the release number by stripping whitespace.
  #
  # @return [String, nil] The normalized number or nil if blank.
  def normalize_number
    self.number = number.to_s.strip.presence
  end
end
