# bin/rails generate migration AddConstrainSc04Language
# bin/rails db:migrate

# frozen_string_literal: true

class AddConstrainSc04Language < ActiveRecord::Migration[8.1]
  def up
    #
    # === SEARCH / LOOKUP INDEXES ===
    #
    execute <<~SQL
      CREATE INDEX IF NOT EXISTS idx_lang_language_title
        ON sc_04_language.lang_language (lang_title);

      CREATE INDEX IF NOT EXISTS idx_lang_doc_title
        ON sc_04_language.lang_doc (doc_title);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX IF EXISTS sc_04_language.idx_lang_doc_title;
      DROP INDEX IF EXISTS sc_04_language.idx_lang_language_title;
    SQL
  end
end
