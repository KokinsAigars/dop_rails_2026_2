# bin/rails generate migration TriggerSc03Dictionary
# bin/rails db:migrate

# frozen_string_literal: true

class TriggerSc03Dictionary < ActiveRecord::Migration[8.1]
  SCHEMA = "sc_03_dictionary"
  TABLES = %w[
    dic_doc
    dic_index
    dic_entry
    dic_scan
    dic_ref
    dic_eg
    dic_quote
    dic_note
  ].freeze

  def change
    reversible do |dir|
      dir.up do
        TABLES.each do |t|
          execute <<~SQL
            DROP TRIGGER IF EXISTS trg_audit_#{t} ON #{SCHEMA}.#{t};

            CREATE TRIGGER trg_audit_#{t}
            AFTER INSERT OR UPDATE OR DELETE ON #{SCHEMA}.#{t}
            FOR EACH ROW
            EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();
          SQL
        end
      end

      dir.down do
        TABLES.each do |t|
          execute <<~SQL
            DROP TRIGGER IF EXISTS trg_audit_#{t} ON #{SCHEMA}.#{t};
          SQL
        end
      end
    end
  end
end
