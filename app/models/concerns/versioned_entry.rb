# frozen_string_literal: true

# Concern that provides immutable, append-only versioning semantics for AR models.
#
# Each logical entity is identified by a stable `root_id`. Individual persisted
# versions share the same `root_id` and increase a numeric `version` counter.
# Exactly one row per `root_id` is marked as `is_current: true`.
#
# Key behaviors:
# - New versions are created by cloning attributes from the current row, applying
#   changes, and atomically marking the previous row as superseded.
# - Writes are wrapped in a DB transaction with explicit row locking to prevent
#   race conditions when computing the next `version`.
# - IDs are UUIDs; the initial record sets `root_id == id` and `version == 1`.
#
# Scopes provided by this concern:
# @!method self.current
#   Rows marked as current for their `root_id`.
#   @return [ActiveRecord::Relation]
# @!method self.history_for(root_id)
#   All versions for the provided `root_id`, sorted newest-first.
#   @param root_id [String] The logical entity identifier shared across versions.
#   @return [ActiveRecord::Relation]
#
# Callbacks:
# - `before_validation :ensure_ids_and_versioning` on create initializes `id`,
#   `root_id`, and `version` for the first persisted row.
module VersionedEntry
  extend ActiveSupport::Concern

  included do
    scope :current, -> { where(is_current: true) }
    scope :history_for, ->(root_id) { where(root_id: root_id).order(version: :desc) }

    before_validation :ensure_ids_and_versioning, on: :create
  end

  # Creates a new version using controller-style request context.
  #
  # NOTE: This helper assumes it is called in a controller-like environment
  # where `params`, `request`, `Current.user`, and `Current.oauth_application`
  # are available, and that `render` is used to return the response.
  # In most applications this logic should live in a controller; the method is
  # provided here for convenience in API endpoints.
  #
  # @return [void]
  # @see #create_new_version!
  # @example In a controller action
  #   # POST /dic_entries/:id/versions
  #   def create_version
  #     # delegates to the concern; renders the created JSON record
  #     super
  #   end
  def create_version
    entry = DicEntry.find(params[:id])

    new_entry = entry.create_new_version!(
      attrs: entry_params.to_h,
      modified_by: {
        source: "api",
        user_id: Current.user&.id,
        oauth_application_id: Current.oauth_application&.id,
        request_id: request.request_id
      }
    )

    render json: new_entry, status: :created
  end

  # Call on a CURRENT row (or any row; we’ll version from the current one for the root).
  # Returns the new row.
  # Creates and returns a new persisted version for the same `root_id`.
  #
  # The method:
  # - Locks the current row for the `root_id` and computes `next_version` safely
  # - Clones attributes from the current row, excluding identity and audit fields
  # - Applies the provided `attrs`
  # - Persists the new row and marks the previous row as superseded
  #
  # @param attrs [Hash{String,Symbol=>Object}] Attribute overrides to apply to the new version
  # @param modified_by [Hash] Audit payload describing the change
  # @option modified_by [String] :source Change origin (e.g., "api")
  # @option modified_by [String, nil] :user_id Acting user id, if any
  # @option modified_by [String, nil] :oauth_application_id OAuth app id, if any
  # @option modified_by [String] :request_id Correlation id for tracing
  # @return [self] The newly created versioned record (instance of `self.class`)
  # @raise [ActiveRecord::RecordInvalid] if validations fail when saving either row
  # @example
  #   new_entry = entry.create_new_version!(
  #     attrs: { title: "Revised" },
  #     modified_by: { source: "api", user_id: current_user.id, request_id: request.request_id }
  #   )
  def create_new_version!(attrs:, modified_by:)
    self.class.transaction do
      # Lock the current row for this root (not just "self")
      base = self.class.where(root_id: root_id).current.lock(true).first ||
             self.class.lock.find(id)

      # Lock all rows for the root while computing next version (prevents races)
      next_version =
        self.class.where(root_id: base.root_id).lock.maximum(:version).to_i + 1

      new_row = self.class.new(
        base.attributes.except(
          "id",
          "root_id",
          "version",
          "created_at",
          "modified_date",
          "modified_by",
          "is_current",
          "superseded_at",
          "superseded_by"
        )
      )

      new_row.assign_attributes(attrs)
      new_row.id = SecureRandom.uuid
      new_row.root_id = base.root_id
      new_row.version = next_version
      new_row.is_current = true
      new_row.superseded_at = nil
      new_row.superseded_by = nil
      new_row.modified_by = modified_by
      new_row.created_at ||= Time.current
      new_row.modified_date = Time.current

      new_row.save!

      base.update!(
        is_current: false,
        superseded_at: Time.current,
        superseded_by: new_row.id,
        modified_by: modified_by,
        modified_date: Time.current
      )

      new_row
    end
  end

  private

  # Initializes identity and versioning fields for the first persisted row.
  #
  # Ensures a UUID `id` is present before validation, sets `root_id` to the
  # same value for the first version, and defaults `version` to 1.
  #
  # @return [void]
  # @!visibility private
  def ensure_ids_and_versioning
    # Ensure we have an id before validation (PG would generate it later otherwise)
    self.id ||= SecureRandom.uuid

    # For the very first version, root_id should equal id
    self.root_id ||= self.id
    self.version ||= 1
  end
end
