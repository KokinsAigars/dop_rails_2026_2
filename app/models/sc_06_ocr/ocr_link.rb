# Sc06Ocr::OcrLink

# frozen_string_literal: true

module Sc06Ocr
  class OcrLink < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_06_ocr.ocr_link"

    belongs_to :page_result,
               class_name: "Sc06Ocr::OcrPageResult",
               foreign_key: :fk_page_result_id,
               inverse_of: :ocr_links

    # optional associations (adjust class_name to your actual models)
    belongs_to :dic_index,
               class_name: "Sc03Dictionary::DicIndex",
               foreign_key: :fk_index_id,
               optional: true

    belongs_to :dic_entry,
               class_name: "Sc03Dictionary::DicEntry",
               foreign_key: :fk_entry_id,
               optional: true

    LINK_KINDS = %w[
      candidate_index
      candidate_entry
      resolved_index
      resolved_entry
      manual
      auto
    ].freeze

    validates :fk_page_result_id, presence: true
    validates :link_kind, presence: true # optionally: inclusion: { in: LINK_KINDS }

    validates :link_conf,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
              allow_nil: true

    validate :must_link_to_index_or_entry

    private

    def must_link_to_index_or_entry
      if fk_index_id.blank? && fk_entry_id.blank?
        errors.add(:base, "Either fk_index_id or fk_entry_id must be present")
      end
    end
  end
end
