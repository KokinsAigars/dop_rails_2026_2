# Sc06Ocr::OcrSourceDoc

# frozen_string_literal: true

module Sc06Ocr
  class OcrSourceDoc < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_06_ocr.ocr_source_doc"

    has_many :ocr_pages,
             class_name: "Sc06Ocr::OcrPage",
             foreign_key: :fk_source_doc_id,
             inverse_of: :source_doc,
             dependent: :restrict_with_exception

    validates :doc_meta, presence: true
  end
end
