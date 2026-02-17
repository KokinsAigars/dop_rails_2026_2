# bin/rails generate migration AddConstrainSc05Audit
# bin/rails db:migrate

# frozen_string_literal: true

class AddConstrainSc05Audit < ActiveRecord::Migration[8.1]
  def up
    # abbr
    add_index "sc_05_audit.abbr_audit_events",
              %i[table_name row_id event_at],
              name: "idx_abbr_audit_row_time"

    add_index "sc_05_audit.abbr_audit_events",
              :event_at,
              name: "idx_abbr_audit_event_at"

    # ref
    add_index "sc_05_audit.ref_audit_events",
              %i[table_name row_id event_at],
              name: "idx_ref_audit_row_time"

    add_index "sc_05_audit.ref_audit_events",
              :event_at,
              name: "idx_ref_audit_event_at"

    # dic_entry
    add_index "sc_05_audit.dic_entry_audit_events",
              %i[table_name row_id event_at],
              name: "idx_dic_entry_audit_row_time"

    add_index "sc_05_audit.dic_entry_audit_events",
              :event_at,
              name: "idx_dic_entry_audit_event_at"

    # sanity checks
    execute <<~SQL
      ALTER TABLE sc_05_audit.abbr_audit_events
        ADD CONSTRAINT chk_abbr_audit_action
        CHECK (lower(action) IN ('insert','update','delete'));

      ALTER TABLE sc_05_audit.ref_audit_events
        ADD CONSTRAINT chk_ref_audit_action
        CHECK (lower(action) IN ('insert','update','delete'));

      ALTER TABLE sc_05_audit.dic_entry_audit_events
        ADD CONSTRAINT chk_dic_entry_audit_action
        CHECK (lower(action) IN ('insert','update','delete'));
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE sc_05_audit.dic_entry_audit_events
        DROP CONSTRAINT IF EXISTS chk_dic_entry_audit_action;

      ALTER TABLE sc_05_audit.ref_audit_events
        DROP CONSTRAINT IF EXISTS chk_ref_audit_action;

      ALTER TABLE sc_05_audit.abbr_audit_events
        DROP CONSTRAINT IF EXISTS chk_abbr_audit_action;
    SQL

    remove_index "sc_05_audit.dic_entry_audit_events", name: "idx_dic_entry_audit_event_at"
    remove_index "sc_05_audit.dic_entry_audit_events", name: "idx_dic_entry_audit_row_time"

    remove_index "sc_05_audit.ref_audit_events", name: "idx_ref_audit_event_at"
    remove_index "sc_05_audit.ref_audit_events", name: "idx_ref_audit_row_time"

    remove_index "sc_05_audit.abbr_audit_events", name: "idx_abbr_audit_event_at"
    remove_index "sc_05_audit.abbr_audit_events", name: "idx_abbr_audit_row_time"
  end
end
