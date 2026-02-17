# Sc06Ocr::OcrReview

# frozen_string_literal: true

module Sc06Ocr
  class OcrReview < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_06_ocr.ocr_review"

    belongs_to :page_result,
               class_name: "Sc06Ocr::OcrPageResult",
               foreign_key: :fk_page_result_id,
               inverse_of: :ocr_review

    REVIEW_STATUSES = %w[pending approved rejected needs_fix].freeze

    validates :fk_page_result_id, presence: true
    validates :review_status, presence: true, inclusion: { in: REVIEW_STATUSES }
    validates :reviewed_by, presence: true
  end
end
