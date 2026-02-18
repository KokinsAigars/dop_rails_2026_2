# app/controllers/dictionary/dic/vocab_controller.rb
module Dictionary
  module Dic
    class VocabController < ApplicationController


      def index
        @lang = params[:lang] || 'pi'
        # Ensure @query is a string, even if params[:q] is missing
        @query = params[:q].to_s.strip

        # Start the base relation
        @terms = Sc03Dictionary::DicVocab.where(lang: @lang)

        if @query.present?
          # 1. SEARCH MODE (No Kaminari needed for top hits)
          # Use the Unicode letter matcher, but only if @query isn't empty
          clean_q = @query.gsub(/[^\p{L}\s]/, '').downcase

          # Check if clean_q is empty after stripping noise (e.g. user just typed "123")
          if clean_q.length > 1 # Only do fuzzy search if they typed at least 2 letters
            @terms = @terms.where(
              "term_norm ILIKE :prefix OR term_norm ILIKE :compound OR term_norm ILIKE :fuzzy",
              prefix: "#{clean_q}%",       # Starts with (agn...)
              compound: "%-#{clean_q}%",   # Starts after a dash (a-baddha)
              fuzzy: "%#{clean_q}%"        # Anywhere (subaddha)
            ).order(
              Arel.sql("CASE
    WHEN term_norm ILIKE '#{clean_q}' THEN 0 -- Exact match first
    WHEN term_norm ILIKE '#{clean_q}%' THEN 1 -- Starts with second
    ELSE 2 -- Fuzzy/Inside matches last
  END"),
              :term_norm
            ).limit(50)
          else
            # For 1 letter, just do a prefix search to keep it fast
            @terms = @terms.where("term_norm ILIKE ?", "#{clean_q}%")
                           .order(:term_norm).limit(50)
          end
        else
          # 2. BROWSE MODE (Kaminari is active here)
          @terms = @terms.order(:term_norm).page(params[:page]).per(100)
        end
      end



        # test inside console
        # Sc03Dictionary::DicVocab.where("term ILIKE ?", "%-baddha%").limit(5)




    end
  end
end


# query = "āgārika"
# search_results = Sc03Dictionary::DicVocab.where(lang: 'pi').where("term_norm ILIKE ?", "#{query}%")
# search_results = Sc03Dictionary::DicVocab.where(lang: 'pi').where("term_norm ILIKE ?", "%#{@query}%")
# puts search_results.to_sql

# Sc03Dictionary::DicVocab.where("term ILIKE ?", "āgārika%").limit(1)
# Sc03Dictionary::DicVocab.where("term_norm ILIKE ?", "agarika%").limit(1)