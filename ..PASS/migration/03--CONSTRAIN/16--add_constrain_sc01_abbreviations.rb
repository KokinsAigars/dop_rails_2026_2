# bin/rails generate migration AddConstrainSc01Abbreviations
# bin/rails db:migrate

# frozen_string_literal: true

class AddConstrainSc01Abbreviations < ActiveRecord::Migration[8.1]
  TABLES = %w[
  abbr_books_periodicals
  abbr_general_terms
  abbr_grammatical_terms
  abbr_publication_sources
  abbr_typographicals
  abbr_docs
  ].freeze

  def up
    # 1) Backfill versioning columns for legacy data
    TABLES.each do |t|
      execute <<~SQL
        UPDATE sc_01_abbreviations.#{t}
        SET
          root_id = COALESCE(root_id, id),
          version = COALESCE(version, 1),
          is_current = COALESCE(is_current, true),
          superseded_at = NULL,
          superseded_by = NULL
        WHERE root_id IS NULL OR version IS NULL;
      SQL
    end

    # 2) Now enforce NOT NULL (optional but recommended after backfill)
    TABLES.each do |t|
      change_column_null "sc_01_abbreviations.#{t}", :root_id, false
      change_column_null "sc_01_abbreviations.#{t}", :version, false
    end

    # 3) Indexes + constraints (after data is consistent)
    # ---- abbr_books_periodicals
    add_index "sc_01_abbreviations.abbr_books_periodicals", :abbr_name,
              name: "idx_abbr_books_periodicals_abbr_name"

    add_index "sc_01_abbreviations.abbr_books_periodicals", :abbr_letter,
              name: "idx_abbr_books_periodicals_abbr_letter"

    add_index "sc_01_abbreviations.abbr_books_periodicals", [:root_id, :version],
              unique: true,
              name: "uq_abbr_books_periodicals_root_version"

    add_index "sc_01_abbreviations.abbr_books_periodicals", :root_id,
              unique: true,
              where: "is_current = true",
              name: "uq_abbr_books_periodicals_root_current"

    add_index "sc_01_abbreviations.abbr_books_periodicals", :superseded_at,
              name: "idx_abbr_books_periodicals_superseded_at"

    # ---- abbr_general_terms
    add_index "sc_01_abbreviations.abbr_general_terms", [:abbr_letter, :abbr_name],
              name: "idx_abbr_general_terms_letter_name"

    add_index "sc_01_abbreviations.abbr_general_terms", :abbr_name,
              name: "idx_abbr_general_terms_name"

    add_index "sc_01_abbreviations.abbr_general_terms", [:root_id, :version],
              unique: true,
              name: "uq_abbr_general_terms_root_version"

    add_index "sc_01_abbreviations.abbr_general_terms", :root_id,
              unique: true,
              where: "is_current = true",
              name: "uq_abbr_general_terms_root_current"

    # ---- abbr_grammatical_terms
    add_index "sc_01_abbreviations.abbr_grammatical_terms", [:abbr_letter, :abbr_name],
              name: "idx_abbr_gram_terms_letter_name"

    add_index "sc_01_abbreviations.abbr_grammatical_terms", :abbr_name,
              name: "idx_abbr_gram_terms_name"

    add_index "sc_01_abbreviations.abbr_grammatical_terms", [:root_id, :version],
              unique: true,
              name: "uq_abbr_gram_terms_root_version"

    add_index "sc_01_abbreviations.abbr_grammatical_terms", :root_id,
              unique: true,
              where: "is_current = true",
              name: "uq_abbr_gram_terms_root_current"

    # ---- abbr_publication_sources
    add_index "sc_01_abbreviations.abbr_publication_sources", :abbr_name,
              name: "idx_abbr_pub_sources_name"

    add_index "sc_01_abbreviations.abbr_publication_sources", [:root_id, :version],
              unique: true,
              name: "uq_abbr_pub_sources_root_version"

    add_index "sc_01_abbreviations.abbr_publication_sources", :root_id,
              unique: true,
              where: "is_current = true",
              name: "uq_abbr_pub_sources_root_current"

    # ---- abbr_typographicals
    add_index "sc_01_abbreviations.abbr_typographicals", :abbr_name,
              name: "idx_abbr_typographicals_name"

    add_index "sc_01_abbreviations.abbr_typographicals", [:root_id, :version],
              unique: true,
              name: "uq_abbr_typographicals_root_version"

    add_index "sc_01_abbreviations.abbr_typographicals", :root_id,
              unique: true,
              where: "is_current = true",
              name: "uq_abbr_typographicals_root_current"

    # ---- abbr_docs
    add_index "sc_01_abbreviations.abbr_docs", :doc_title,
              name: "idx_abbr_docs_doc_title"

    add_index "sc_01_abbreviations.abbr_docs", [:root_id, :version],
              unique: true,
              name: "uq_abbr_docs_root_version"

    add_index "sc_01_abbreviations.abbr_docs", :root_id,
              unique: true,
              where: "is_current = true",
              name: "uq_abbr_docs_root_current"

  end

  def down

    # drop indexes by name
    remove_index "sc_01_abbreviations.abbr_books_periodicals", name: "idx_abbr_books_periodicals_abbr_name", if_exists: true
    remove_index "sc_01_abbreviations.abbr_books_periodicals", name: "idx_abbr_books_periodicals_abbr_letter", if_exists: true
    remove_index "sc_01_abbreviations.abbr_books_periodicals", name: "uq_abbr_books_periodicals_root_version", if_exists: true
    remove_index "sc_01_abbreviations.abbr_books_periodicals", name: "uq_abbr_books_periodicals_root_current", if_exists: true
    remove_index "sc_01_abbreviations.abbr_books_periodicals", name: "idx_abbr_books_periodicals_superseded_at", if_exists: true

    remove_index "sc_01_abbreviations.abbr_general_terms", name: "idx_abbr_general_terms_letter_name", if_exists: true
    remove_index "sc_01_abbreviations.abbr_general_terms", name: "idx_abbr_general_terms_name", if_exists: true
    remove_index "sc_01_abbreviations.abbr_general_terms", name: "uq_abbr_general_terms_root_version", if_exists: true
    remove_index "sc_01_abbreviations.abbr_general_terms", name: "uq_abbr_general_terms_root_current", if_exists: true

    remove_index "sc_01_abbreviations.abbr_grammatical_terms", name: "idx_abbr_gram_terms_letter_name", if_exists: true
    remove_index "sc_01_abbreviations.abbr_grammatical_terms", name: "idx_abbr_gram_terms_name", if_exists: true
    remove_index "sc_01_abbreviations.abbr_grammatical_terms", name: "uq_abbr_gram_terms_root_version", if_exists: true
    remove_index "sc_01_abbreviations.abbr_grammatical_terms", name: "uq_abbr_gram_terms_root_current", if_exists: true

    remove_index "sc_01_abbreviations.abbr_publication_sources", name: "idx_abbr_pub_sources_name", if_exists: true
    remove_index "sc_01_abbreviations.abbr_publication_sources", name: "uq_abbr_pub_sources_root_version", if_exists: true
    remove_index "sc_01_abbreviations.abbr_publication_sources", name: "uq_abbr_pub_sources_root_current", if_exists: true

    remove_index "sc_01_abbreviations.abbr_typographicals", name: "idx_abbr_typographicals_name", if_exists: true
    remove_index "sc_01_abbreviations.abbr_typographicals", name: "uq_abbr_typographicals_root_version", if_exists: true
    remove_index "sc_01_abbreviations.abbr_typographicals", name: "uq_abbr_typographicals_root_current", if_exists: true

    remove_index "sc_01_abbreviations.abbr_docs", name: "idx_abbr_docs_doc_title", if_exists: true
    remove_index "sc_01_abbreviations.abbr_docs", name: "uq_abbr_docs_root_version", if_exists: true
    remove_index "sc_01_abbreviations.abbr_docs", name: "uq_abbr_docs_root_current", if_exists: true

    # loosen NOT NULL (to truly reverse)
    TABLES.each do |t|
      change_column_null "sc_01_abbreviations.#{t}", :version, true
      change_column_null "sc_01_abbreviations.#{t}", :root_id, true
    end
  end
end
