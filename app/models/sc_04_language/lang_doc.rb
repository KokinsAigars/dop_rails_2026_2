# Sc04Language::LangDoc

# frozen_string_literal: true

module Sc04Language
  class LangDoc < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_04_language.lang_doc"

    validates :doc_title, presence: true
  end
end
