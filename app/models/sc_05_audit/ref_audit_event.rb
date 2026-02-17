# Sc05Audit::RefAuditEvent

# frozen_string_literal: true

module Sc05Audit
  class RefAuditEvent < AuditEvent
    self.table_name = "sc_05_audit.ref_audit_events"
  end
end
