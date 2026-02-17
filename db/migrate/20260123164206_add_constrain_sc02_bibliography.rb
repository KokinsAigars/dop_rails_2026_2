# bin/rails generate migration AddConstrainSc02Bibliography
# bin/rails db:migrate

# frozen_string_literal: true

class AddConstrainSc02Bibliography < ActiveRecord::Migration[8.1]
  TABLES = %w[
  ref_bibliography
  ref_internet_sources
  ref_texts
  ref_doc
  ].freeze

  def up
    # 1) Backfill versioning columns for legacy data
    TABLES.each do |t|
      execute <<~SQL
        UPDATE sc_02_bibliography.#{t}
        SET
        root_id = id,
        version = 1,
        is_current = true,
        superseded_at = NULL,
        superseded_by = NULL
        WHERE root_id IS NULL OR version IS NULL;
      SQL
    end

    # 2) Enforce NOT NULL after backfill
    TABLES.each do |t|
      change_column_null "sc_02_bibliography.#{t}", :root_id, false
      change_column_null "sc_02_bibliography.#{t}", :version, false
    end

    # 3) Versioning constraints (the same pattern on every table)
    TABLES.each do |t|
      add_index "sc_02_bibliography.#{t}",
                [ :root_id, :version ],
                unique: true,
                name: "uq_#{t}_root_version"

      add_index "sc_02_bibliography.#{t}",
                :root_id,
                unique: true,
                where: "is_current = true",
                name: "uq_#{t}_root_current"
    end

    # 4) functional/search indexes
    add_index "sc_02_bibliography.ref_bibliography", :ref_abbrev,
              name: "idx_ref_bibliography_ref_abbrev"
    add_index "sc_02_bibliography.ref_bibliography", :ref_letter,
              name: "idx_ref_bibliography_ref_letter"
    add_index "sc_02_bibliography.ref_bibliography", :ref_type,
              name: "idx_ref_bibliography_ref_type"

    # Optional
    add_index "sc_02_bibliography.ref_internet_sources", :ref_url,
              name: "idx_ref_internet_sources_ref_url"

    add_index "sc_02_bibliography.ref_texts", :ref_abbrev,
              name: "idx_ref_texts_ref_abbrev"
    add_index "sc_02_bibliography.ref_texts", :ref_texts_no,
              name: "idx_ref_texts_ref_texts_no"

    add_index "sc_02_bibliography.ref_doc", :doc_title,
              name: "idx_ref_doc_doc_title"
  end

  def down
    # drop your extra indexes first
    remove_index "sc_02_bibliography.ref_bibliography", name: "idx_ref_bibliography_ref_abbrev"
    remove_index "sc_02_bibliography.ref_bibliography", name: "idx_ref_bibliography_ref_letter"
    remove_index "sc_02_bibliography.ref_bibliography", name: "idx_ref_bibliography_ref_type"

    remove_index "sc_02_bibliography.ref_internet_sources", name: "idx_ref_internet_sources_ref_url"

    remove_index "sc_02_bibliography.ref_texts", name: "idx_ref_texts_ref_abbrev"
    remove_index "sc_02_bibliography.ref_texts", name: "idx_ref_texts_ref_texts_no"

    remove_index "sc_02_bibliography.ref_doc", name: "idx_ref_doc_doc_title"

    # drop versioning indexes
    TABLES.each do |t|
      remove_index "sc_02_bibliography.#{t}", name: "uq_#{t}_root_version"
      remove_index "sc_02_bibliography.#{t}", name: "uq_#{t}_root_current"
    end

    # loosen nullability again (true rollback)
    TABLES.each do |t|
      change_column_null "sc_02_bibliography.#{t}", :version, true
      change_column_null "sc_02_bibliography.#{t}", :root_id, true
    end
  end
end
