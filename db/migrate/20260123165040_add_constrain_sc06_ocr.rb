# bin/rails generate migration AddConstrainSc06Ocr
# bin/rails db:migrate

# frozen_string_literal: true

class AddConstrainSc06Ocr < ActiveRecord::Migration[8.1]
  def up
    #
    # === BACKFILL / NORMALIZATION (safe, minimal) ===
    #
    execute <<~SQL
        UPDATE sc_06_ocr.ocr_run
        SET status = 'ok'
        WHERE status IS NULL OR btrim(status) = '';

        UPDATE sc_06_ocr.ocr_review
         SET review_status = 'pending'
        WHERE review_status IS NULL OR btrim(review_status) = '';
    SQL

    #
    # === FOREIGN KEYS ===
    #

    add_foreign_key "sc_06_ocr.ocr_page",
                    "sc_06_ocr.ocr_source_doc",
                    column: :fk_source_doc_id,
                    on_delete: :cascade,
                    name: "fk_ocr_page_source_doc"

    add_foreign_key "sc_06_ocr.ocr_page_result",
                    "sc_06_ocr.ocr_run",
                    column: :fk_run_id,
                    on_delete: :cascade,
                    name: "fk_ocr_page_result_run"

    add_foreign_key "sc_06_ocr.ocr_page_result",
                    "sc_06_ocr.ocr_page",
                    column: :fk_page_id,
                    on_delete: :cascade,
                    name: "fk_ocr_page_result_page"

    add_foreign_key "sc_06_ocr.ocr_token",
                    "sc_06_ocr.ocr_page_result",
                    column: :fk_page_result_id,
                    on_delete: :cascade,
                    name: "fk_ocr_token_page_result"

    add_foreign_key "sc_06_ocr.ocr_review",
                    "sc_06_ocr.ocr_page_result",
                    column: :fk_page_result_id,
                    on_delete: :cascade,
                    name: "fk_ocr_review_page_result"

    add_foreign_key "sc_06_ocr.ocr_link",
                    "sc_06_ocr.ocr_page_result",
                    column: :fk_page_result_id,
                    on_delete: :cascade,
                    name: "fk_ocr_link_page_result"

    # cross-schema links
    add_foreign_key "sc_06_ocr.ocr_link",
                    "sc_03_dictionary.dic_index",
                    column: :fk_index_id,
                    on_delete: :nullify,
                    name: "fk_ocr_link_dic_index"

    add_foreign_key "sc_06_ocr.ocr_link",
                    "sc_03_dictionary.dic_entry",
                    column: :fk_entry_id,
                    on_delete: :nullify,
                    name: "fk_ocr_link_dic_entry"

    #
    # === UNIQUES / INDEXES ===
    #

    add_index "sc_06_ocr.ocr_source_doc",
              :source_sha256,
              unique: true,
              name: "uq_ocr_source_doc_sha256"

    add_index "sc_06_ocr.ocr_page",
              %i[fk_source_doc_id page_no],
              unique: true,
              name: "uq_ocr_page_doc_page_no"

    add_index "sc_06_ocr.ocr_run",
              %i[engine started_at],
              name: "ix_ocr_run_engine_started_at"

    add_index "sc_06_ocr.ocr_page_result",
              %i[fk_run_id fk_page_id],
              unique: true,
              name: "uq_ocr_page_result_run_page"

    add_index "sc_06_ocr.ocr_page_result",
              :fk_page_id,
              name: "ix_ocr_page_result_page"

    add_index "sc_06_ocr.ocr_token",
              %i[fk_page_result_id token_no],
              unique: true,
              name: "uq_ocr_token_result_token_no"

    add_index "sc_06_ocr.ocr_token",
              :text_norm,
              name: "ix_ocr_token_text_norm"

    add_index "sc_06_ocr.ocr_review",
              :review_status,
              name: "ix_ocr_review_status"

    add_index "sc_06_ocr.ocr_review",
              :fk_page_result_id,
              unique: true,
              name: "uq_ocr_review_page_result"

    add_index "sc_06_ocr.ocr_link",
              :fk_index_id,
              name: "ix_ocr_link_fk_index_id"

    add_index "sc_06_ocr.ocr_link",
              :fk_entry_id,
              name: "ix_ocr_link_fk_entry_id"

    add_index "sc_06_ocr.ocr_link",
              :link_kind,
              name: "ix_ocr_link_kind"

    #
    # === OPTIONAL SANITY CHECKS (cheap, useful) ===
    #
    execute <<~SQL
      ALTER TABLE sc_06_ocr.ocr_page
        ADD CONSTRAINT chk_ocr_page_page_no_positive
        CHECK (page_no > 0);

      ALTER TABLE sc_06_ocr.ocr_token
        ADD CONSTRAINT chk_ocr_token_token_no_nonneg
        CHECK (token_no >= 0);
    SQL
  end

  def down
    execute <<~SQL
ALTER TABLE sc_06_ocr.ocr_token
DROP CONSTRAINT IF EXISTS chk_ocr_token_token_no_nonneg;

      ALTER TABLE sc_06_ocr.ocr_page
        DROP CONSTRAINT IF EXISTS chk_ocr_page_page_no_positive;
    SQL

    # ocr_link indexes
    remove_index "sc_06_ocr.ocr_link", name: "ix_ocr_link_kind"
    remove_index "sc_06_ocr.ocr_link", name: "ix_ocr_link_fk_entry_id"
    remove_index "sc_06_ocr.ocr_link", name: "ix_ocr_link_fk_index_id"

    # ocr_review indexes
    remove_index "sc_06_ocr.ocr_review", name: "uq_ocr_review_page_result"
    remove_index "sc_06_ocr.ocr_review", name: "ix_ocr_review_status"

    # ocr_token indexes
    remove_index "sc_06_ocr.ocr_token", name: "ix_ocr_token_text_norm"
    remove_index "sc_06_ocr.ocr_token", name: "uq_ocr_token_result_token_no"

    # ocr_page_result indexes
    remove_index "sc_06_ocr.ocr_page_result", name: "ix_ocr_page_result_page"
    remove_index "sc_06_ocr.ocr_page_result", name: "uq_ocr_page_result_run_page"

    # ocr_run index
    remove_index "sc_06_ocr.ocr_run", name: "ix_ocr_run_engine_started_at"

    # ocr_page index
    remove_index "sc_06_ocr.ocr_page", name: "uq_ocr_page_doc_page_no"

    # ocr_source_doc index
    remove_index "sc_06_ocr.ocr_source_doc", name: "uq_ocr_source_doc_sha256"

    # Foreign keys (reverse order is fine; explicit names)
    remove_foreign_key "sc_06_ocr.ocr_link",        name: "fk_ocr_link_dic_entry"
    remove_foreign_key "sc_06_ocr.ocr_link",        name: "fk_ocr_link_dic_index"
    remove_foreign_key "sc_06_ocr.ocr_link",        name: "fk_ocr_link_page_result"
    remove_foreign_key "sc_06_ocr.ocr_review",      name: "fk_ocr_review_page_result"
    remove_foreign_key "sc_06_ocr.ocr_token",       name: "fk_ocr_token_page_result"
    remove_foreign_key "sc_06_ocr.ocr_page_result", name: "fk_ocr_page_result_page"
    remove_foreign_key "sc_06_ocr.ocr_page_result", name: "fk_ocr_page_result_run"
    remove_foreign_key "sc_06_ocr.ocr_page",        name: "fk_ocr_page_source_doc"
  end
end
