# Sc06Ocr::OcrRun

# frozen_string_literal: true

module Sc06Ocr
  class OcrRun < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_06_ocr.ocr_run"

    has_many :ocr_page_results,
             class_name: "Sc06Ocr::OcrPageResult",
             foreign_key: :fk_run_id,
             inverse_of: :run,
             dependent: :restrict_with_exception

    RUN_STATUSES = %w[
      ok
      running
      failed
      partial
      cancelled
    ].freeze

    validates :engine, presence: true
    validates :lang_hint, presence: true
    validates :config, presence: true
    validates :started_at, presence: true
    validates :status, presence: true # optional: inclusion: { in: RUN_STATUSES }
  end
end
