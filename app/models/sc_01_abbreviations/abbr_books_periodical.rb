# Sc01Abbreviations::AbbrBooksPeriodical

# frozen_string_literal: true

module Sc01Abbreviations
  # Abbreviation record for books and periodicals used in the SC‑01 registry.
  #
  # This model maps to the Postgres table `sc_01_abbreviations.abbr_books_periodicals`
  # and includes common mixins for versioning and modified date tracking.
  #
  # Mixins:
  # - {VersionedEntry} – provides versioning helpers for entries.
  # - {HasModifiedDate} – keeps the `modified_date` up to date.
  #
  # @!attribute [rw] abbr_name
  #   @return [String] Required abbreviation text. Must be present.
  # @!attribute [rw] abbr_letter
  #   @return [String, nil] Optional single-letter code (max length: 1).
  #
  # @see .table_name for the exact database table used by this model.
  class AbbrBooksPeriodical < ApplicationRecord
    include VersionedEntry
    include HasModifiedDate

    # Explicit database table mapping
    self.table_name = "sc_01_abbreviations.abbr_books_periodicals"

    # Validations
    validates :abbr_name, presence: true
    validates :abbr_letter, length: { maximum: 1 }, allow_nil: true
  end
end



# table "sc_01_abbreviations.abbr_books_periodicals"
# id:           :uuid, default: -> { "gen_random_uuid()" }
# t.string      :abbr_letter, limit: 1
# t.text        :abbr_name, null: false
# t.text        :abbr_id_est
# t.text        :abbr_lv
# t.text        :abbr_number
# t.uuid        :abbr_ref_id
# t.text        :abbr_note
# t.text        :abbr_source
# t.text        :abbr_source_text
# t.text        :abbr_citation
# t.text        :abbr_citation_transl
# t.text        :abbr_citation_2
# t.text        :abbr_citation_method
# t.text        :abbr_citation_method_2
# t.boolean     :revision, null: false, default: false
# t.text        :revision_comment
# t.uuid        :root_id
# t.integer     :version
# t.boolean     :is_current, null: false, default: true
# t.datetime    :superseded_at
# t.uuid        :superseded_by
# t.timestamp   :created_at,    null: false, default: -> { "CURRENT_TIMESTAMP" }
# t.timestamp   :modified_date, null: false, default: -> { "CURRENT_TIMESTAMP" }
# t.jsonb       :modified_by
