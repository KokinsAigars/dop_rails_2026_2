# Sc05Audit::AbbrAuditEvent

# frozen_string_literal: true

module Sc05Audit
  class AbbrAuditEvent < AuditEvent
    self.table_name = "sc_05_audit.abbr_audit_events"
  end
end
