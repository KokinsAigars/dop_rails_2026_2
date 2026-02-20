# app/controllers/dictionary/dic/vocab_controller.rb
module Dictionary
  module Dic
    class SearchIndexesController < ApplicationController


      def index
        @query = params[:q].to_s.strip
        @lang = params[:lang] || 'pi'
        @current_release = DbRelease.current.first

        # 1. Start with the base scope and common filters
        # We move DISTINCT ON here, but be careful: ORDER must start with the DISTINCT columns
        scope = Sc03Dictionary::DicSearchIndex.all
        scope = scope.where(lang: @lang) if @lang.present?

        if @query.present?
          if @query.start_with?('"') && @query.end_with?('"')
            # EXACT MODE
            literal_q = @query.gsub('"', '')
            clean_q = Sc03Dictionary::DicSearchIndex.normalize(literal_q)

            scope = scope.where("term = :raw OR term_norm = :clean", raw: literal_q, clean: clean_q)
                         .order(:term_norm)
          else
            # FUZZY MODE
            clean_q = Sc03Dictionary::DicSearchIndex.normalize(@query)
            quoted_q = Sc03Dictionary::DicSearchIndex.connection.quote(@query)
            quoted_clean = Sc03Dictionary::DicSearchIndex.connection.quote(clean_q)

            scope = scope.select("*,
                          CASE
                            WHEN term = #{quoted_q} THEN 0
                            WHEN term_norm = #{quoted_clean} THEN 1
                            WHEN term_norm LIKE #{Sc03Dictionary::DicSearchIndex.connection.quote(clean_q + '%')} THEN 2
                            ELSE 3
                          END AS search_rank")
                         .where("term_norm ILIKE :q OR term ILIKE :raw", q: "%#{clean_q}%", raw: "%#{@query}%")
                         .order("search_rank", "LENGTH(term_norm) ASC", "term_norm")
          end
        else
          # BROWSE MODE
          scope = scope.order(:term_norm)
        end

        # 2. FINALIZE with Pagination
        # Replace .limit(50) with .page().per()
        # This ensures Kaminari methods (total_pages, etc.) are ALWAYS present.
        @terms = scope.page(params[:page]).per(@query.present? ? 50 : 100)
      end



    end
  end
end

# test inside console
# Sc03Dictionary::DicVocab.where("term ILIKE ?", "%-baddha%").limit(5)
#
# word = Sc03Dictionary::DicVocab.find_by("term LIKE ?", "%a-bhāvi%")
# p word&.term
# p word&.term_norm
#
#  Sc03Dictionary::DicVocab.where("term_norm LIKE '%-%'").count
