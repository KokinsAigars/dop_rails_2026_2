# bin/rails generate migration AddConstrainSc07eHash
# bin/rails db:migrate

# frozen_string_literal: true

class AddConstrainSc07eHash < ActiveRecord::Migration[8.1]
  def up
    #
    # temporary_hash
    #
    execute <<~SQL
      CREATE UNIQUE INDEX IF NOT EXISTS uq_temporary_hash_dic_index_hash
        ON sc_07_hash.temporary_hash (dic_index_hash);

      CREATE INDEX IF NOT EXISTS ix_temporary_hash_fk_index_id
        ON sc_07_hash.temporary_hash (fk_index_id);
    SQL

    add_foreign_key "sc_07_hash.temporary_hash",
                    "sc_03_dictionary.dic_index",
                    column: :fk_index_id,
                    on_delete: :cascade,
                    name: "fk_temporary_hash_index_id"

    #
    # executed_sql_scripts
    #
    execute <<~SQL
      CREATE UNIQUE INDEX IF NOT EXISTS uq_executed_sql_scripts_file_hash
        ON sc_07_hash.executed_sql_scripts (file_hash);

      CREATE INDEX IF NOT EXISTS ix_executed_sql_scripts_file_path
        ON sc_07_hash.executed_sql_scripts (file_path);
    SQL
  end

  def down
    #
    # executed_sql_scripts
    #
    execute <<~SQL
      DROP INDEX IF EXISTS sc_07_hash.ix_executed_sql_scripts_file_path;
      DROP INDEX IF EXISTS sc_07_hash.uq_executed_sql_scripts_file_hash;
    SQL

    #
    # temporary_hash
    #
    remove_foreign_key "sc_07_hash.temporary_hash",
                       name: "fk_temporary_hash_index_id"

    execute <<~SQL
      DROP INDEX IF EXISTS sc_07_hash.ix_temporary_hash_fk_index_id;
      DROP INDEX IF EXISTS sc_07_hash.uq_temporary_hash_dic_index_hash;
    SQL
  end
end
