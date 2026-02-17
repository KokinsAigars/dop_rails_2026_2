# Sc05Audit::AuditEvent

# frozen_string_literal: true

module Sc05Audit
  class AuditEvent < ApplicationRecord
    self.abstract_class = true

    # Avoid Rails trying to look up "audit_events" in public schema
    # Each subclass sets its own full schema-qualified table_name.

    ACTIONS = %w[INSERT UPDATE DELETE].freeze

    validates :event_at, :action, :table_name, :row_id, presence: true
    validates :action, inclusion: { in: ACTIONS }, allow_nil: true

    # Helpful defaults
    scope :recent, -> { order(event_at: :desc) }
    scope :for_row, ->(uuid) { where(row_id: uuid) }
    scope :for_table, ->(name) { where(table_name: name) }
  end
end
