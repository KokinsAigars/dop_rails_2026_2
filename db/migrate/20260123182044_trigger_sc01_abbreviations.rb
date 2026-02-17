# bin/rails generate migration TriggerSc01Abbreviations
# bin/rails db:migrate

# frozen_string_literal: true

class TriggerSc01Abbreviations < ActiveRecord::Migration[8.1]
  TABLES = %w[
    abbr_books_periodicals
    abbr_general_terms
    abbr_grammatical_terms
    abbr_publication_sources
    abbr_typographicals
    abbr_docs
  ].freeze

  def up
    TABLES.each do |t|
      execute <<~SQL
        DROP TRIGGER IF EXISTS trg_audit_#{t} ON sc_01_abbreviations.#{t};

        CREATE TRIGGER trg_audit_#{t}
        AFTER INSERT OR UPDATE OR DELETE ON sc_01_abbreviations.#{t}
        FOR EACH ROW
        EXECUTE FUNCTION sc_05_audit.fn_log_audit_event();
      SQL
    end
  end

  def down
    TABLES.each do |t|
      execute <<~SQL
        DROP TRIGGER IF EXISTS trg_audit_#{t} ON sc_01_abbreviations.#{t};
      SQL
    end
  end
end
