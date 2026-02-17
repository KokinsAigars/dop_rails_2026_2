# frozen_string_literal: true

class GlobalSearchService
  def self.search(q)
    return [] if q.blank?

    results = []

    results += AbbrBooksPeriodical.search(q).map { |r| format_result(r, "abbr_books_periodicals") }
    results += AbbrGeneralTerm.search(q).map { |r| format_result(r, "abbr_general_term") }
    results += AbbrGrammaticalTerm.search(q).map { |r| format_result(r, "abbr_grammatical_term") }

    results

    results.sort_by! do |item|
      abbr_name = item[:abbr_name].to_s.downcase

      starts_with = abbr_name.start_with?(q.downcase) ? 0 : 1
      [ starts_with, abbr_name ]
    end
  end

  def self.format_result(record, type)
    puts "type: #{type}"
    puts "record: #{record.try(:abbr_name)}"

    {
      id: record.id,
      type: type,
      title: record.try(:abbr_name) || record.try(:name),
      subtitle: record.try(:abbr_citation) || "",
      model: record.class.to_s,
      record: record,
      url: route_for(record)
    }
  end

  # to find routes for each model in schema
  def self.route_for(record)
    helpers = Rails.application.routes.url_helpers
    locale = I18n.locale

    case record
    when AbbrBooksPeriodical
      helpers.send("abbr_books_periodicals_#{locale}_path", record)
    when AbbrGeneralTerm
      helpers.send("abbr_general_terms_#{locale}_path", record)
    when AbbrGrammaticalTerm
      helpers.send("abbr_grammatical_terms_#{locale}_path", record)
    else
      "#"
    end
  end
end

# rails routes | grep abbr
# url: Rails.application.routes.url_helpers.url_for(record)
# url: Rails.application.routes.url_helpers.abbr_books_periodical_path(record)
