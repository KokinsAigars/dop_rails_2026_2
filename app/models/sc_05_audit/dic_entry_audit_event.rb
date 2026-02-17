# Sc05Audit::DicEntryAuditEvent

# frozen_string_literal: true

module Sc05Audit
  class DicEntryAuditEvent < AuditEvent
    self.table_name = "sc_05_audit.dic_entry_audit_events"
  end
end
