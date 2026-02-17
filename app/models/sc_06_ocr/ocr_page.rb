# Sc06Ocr::OcrPage

# frozen_string_literal: true

module Sc06Ocr
  class OcrPage < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_06_ocr.ocr_page"

    belongs_to :source_doc,
               class_name: "Sc06Ocr::OcrSourceDoc",
               foreign_key: :fk_source_doc_id,
               inverse_of: :ocr_pages

    has_many :ocr_page_results,
             class_name: "Sc06Ocr::OcrPageResult",
             foreign_key: :fk_page_id,
             inverse_of: :page,
             dependent: :restrict_with_exception

    validates :fk_source_doc_id, presence: true
    validates :page_no,
              presence: true,
              numericality: { only_integer: true, greater_than: 0 }

    validates :page_meta, presence: true

    validates :image_width,
              numericality: { only_integer: true, greater_than: 0 },
              allow_nil: true
    validates :image_height,
              numericality: { only_integer: true, greater_than: 0 },
              allow_nil: true
    validates :dpi,
              numericality: { only_integer: true, greater_than: 0 },
              allow_nil: true
  end
end
