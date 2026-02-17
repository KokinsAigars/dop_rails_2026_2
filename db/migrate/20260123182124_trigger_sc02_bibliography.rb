# bin/rails generate migration TriggerSc02Bibliography
# bin/rails db:migrate

# frozen_string_literal: true

class TriggerSc02Bibliography < ActiveRecord::Migration[8.1]
  TABLES = %w[
    ref_bibliography
    ref_internet_sources
    ref_texts
    ref_doc
  ].freeze

  def up
    TABLES.each do |t|
      execute <<~SQL
        DROP TRIGGER IF EXISTS trg_audit_#{t} ON sc_02_bibliography.#{t};

        CREATE TRIGGER trg_audit_#{t}
        AFTER INSERT OR UPDATE OR DELETE ON sc_02_bibliography.#{t}
        FOR EACH ROW
        EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();
      SQL
    end
  end

  def down
    TABLES.each do |t|
      execute <<~SQL
        DROP TRIGGER IF EXISTS trg_audit_#{t} ON sc_02_bibliography.#{t};
      SQL
    end
  end
end
