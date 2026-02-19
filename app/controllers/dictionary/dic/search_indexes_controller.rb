# app/controllers/dictionary/dic/vocab_controller.rb
module Dictionary
  module Dic
    class SearchIndexesController < ApplicationController


      def index
        @query = params[:q].to_s.strip
        @lang = params[:lang] || 'pi'

        # Fetch the current release metadata
        @current_release = DbRelease.current.first

        # Use 'distinct on' or group by if you want to force unique words
        @terms = Sc03Dictionary::DicSearchIndex
                   .where("term_norm ILIKE ?", "%#{params[:q]}%")
                   .order(:term, :fk_index_id)
                   .select("DISTINCT ON (term, fk_index_id) *")
        @terms = @terms.where(lang: @lang) if @lang.present?
        @terms = @terms.limit(100)

        if @query.present?
          # Detect if the user used "exact quotes"
          if @query.start_with?('"') && @query.end_with?('"')
            # EXACT MODE: Strip quotes and search for the literal string only
            literal_q = @query.gsub('"', '')
            clean_q = Sc03Dictionary::DicSearchIndex.normalize(literal_q)

            @terms = @terms.where("term = :raw OR term_norm = :clean", raw: literal_q, clean: clean_q)
                           .order(:term_norm)
                           .limit(50)
          else
            # FUZZY MODE: (Your existing logic)
            clean_q = Sc03Dictionary::DicSearchIndex.normalize(@query)

            @terms = @terms.where(
              "term_norm ILIKE :q OR term ILIKE :raw",
              q: "%#{clean_q}%",
              raw: "%#{@query}%"
            ).order(
              Arel.sql("CASE
                WHEN term = #{Sc03Dictionary::DicSearchIndex.connection.quote(@query)} THEN 0
                WHEN term_norm = #{Sc03Dictionary::DicSearchIndex.connection.quote(clean_q)} THEN 1
                WHEN term_norm LIKE #{Sc03Dictionary::DicSearchIndex.connection.quote(clean_q + '%')} THEN 2
                ELSE 3
              END"),
              Arel.sql("LENGTH(term_norm) ASC"),
              :term_norm
            ).limit(50)
          end
        else
          @terms = @terms.order(:term_norm).page(params[:page]).per(100)
        end
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
