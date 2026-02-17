# Sc06Ocr::OcrToken

# frozen_string_literal: true

module Sc06Ocr
  class OcrToken < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_06_ocr.ocr_token"

    # Associations
    # If your table is named sc_06_ocr.ocr_page_result and model is Sc06Ocr::OcrPageResult:
    belongs_to :page_result,
               class_name: "Sc06Ocr::OcrPageResult",
               foreign_key: :fk_page_result_id,
               inverse_of: :ocr_tokens

    # Validations (mirror DB invariants + basic sanity)
    validates :fk_page_result_id, presence: true
    validates :token_no,
              presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    validates :text, presence: true
    validates :text_norm, presence: true
    validates :bbox, presence: true
  end
end
