# app/controllers/dictionary/dic/vocab_controller.rb
module Dictionary
  module Dic
    class VocabController < ApplicationController


      def index
        @query = params[:q].to_s.strip
        @lang = params[:lang] || 'pi'
        @terms = Sc03Dictionary::DicVocab.where(lang: @lang)

        if @query.present?
          # Detect if the user used "exact quotes"
          if @query.start_with?('"') && @query.end_with?('"')
            # EXACT MODE: Strip quotes and search for the literal string only
            literal_q = @query.gsub('"', '')
            clean_q = Sc03Dictionary::DicVocab.normalize(literal_q)

            @terms = @terms.where("term = :raw OR term_norm = :clean", raw: literal_q, clean: clean_q)
                           .order(:term_norm)
                           .limit(50)
          else
            # FUZZY MODE: (Your existing logic)
            clean_q = Sc03Dictionary::DicVocab.normalize(@query)

            @terms = @terms.where(
              "term_norm ILIKE :q OR term ILIKE :raw",
              q: "%#{clean_q}%",
              raw: "%#{@query}%"
            ).order(
              Arel.sql("CASE
          WHEN term = #{Sc03Dictionary::DicVocab.connection.quote(@query)} THEN 0
          WHEN term_norm = #{Sc03Dictionary::DicVocab.connection.quote(clean_q)} THEN 1
          WHEN term_norm LIKE #{Sc03Dictionary::DicVocab.connection.quote(clean_q + '%')} THEN 2
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



        # test inside console
        # Sc03Dictionary::DicVocab.where("term ILIKE ?", "%-baddha%").limit(5)
        #
        # word = Sc03Dictionary::DicVocab.find_by("term LIKE ?", "%a-bhāvi%")
        # p word&.term
        # p word&.term_norm
        #
        #  Sc03Dictionary::DicVocab.where("term_norm LIKE '%-%'").count



    end
  end
end


# query = "āgārika"
# search_results = Sc03Dictionary::DicVocab.where(lang: 'pi').where("term_norm ILIKE ?", "#{query}%")
# search_results = Sc03Dictionary::DicVocab.where(lang: 'pi').where("term_norm ILIKE ?", "%#{@query}%")
# puts search_results.to_sql

# Sc03Dictionary::DicVocab.where("term ILIKE ?", "āgārika%").limit(1)
# Sc03Dictionary::DicVocab.where("term_norm ILIKE ?", "agarika%").limit(1)