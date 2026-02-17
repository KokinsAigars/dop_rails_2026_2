# Sc06Ocr::OcrPageResult

# frozen_string_literal: true

module Sc06Ocr
  class OcrPageResult < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_06_ocr.ocr_page_result"

    belongs_to :run,
               class_name: "Sc06Ocr::OcrRun",
               foreign_key: :fk_run_id,
               inverse_of: :ocr_page_results

    belongs_to :page,
               class_name: "Sc06Ocr::OcrPage",
               foreign_key: :fk_page_id,
               inverse_of: :ocr_page_results

    has_many :ocr_tokens,
             class_name: "Sc06Ocr::OcrToken",
             foreign_key: :fk_page_result_id,
             inverse_of: :page_result,
             dependent: :delete_all

    has_one :ocr_review,
            class_name: "Sc06Ocr::OcrReview",
            foreign_key: :fk_page_result_id,
            inverse_of: :page_result,
            dependent: :delete

    has_many :ocr_links,
             class_name: "Sc06Ocr::OcrLink",
             foreign_key: :fk_page_result_id,
             inverse_of: :page_result,
             dependent: :delete_all

    validates :fk_run_id, presence: true
    validates :fk_page_id, presence: true
    validates :raw_json, presence: true
    validates :warnings, presence: true
  end
end
