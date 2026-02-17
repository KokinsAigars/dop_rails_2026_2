# Sc04Language::LangLanguage

# frozen_string_literal: true

module Sc04Language
  class LangLanguage < ApplicationRecord
    include HasModifiedDate

    self.table_name = "sc_04_language.lang_language"

    validates :lang_title, presence: true
  end
end
