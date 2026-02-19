# app/controllers/dictionary/dic/vocab_controller.rb
module Dictionary
  module Dic
    class VocabController < ApplicationController


      def index
        @query = params[:q].to_s.strip
        @lang = params[:lang] || 'pi'
        @terms = Sc03Dictionary::DicVocab.where(lang: @lang)

        if @query.present?
          # 1. Standard clean (abhavita)
          clean_q = Sc03Dictionary::DicVocab.normalize(@query)

          # 2. Flexible version (a%bhavita)
          # This turns the hyphen into a wildcard so it matches "a-bhāvita" OR "abhāvita"
          flex_q = @query.downcase
                         .tr('āīūṃṇñṭḍḷščžēģķļņŗ', 'aiumnntdlsczegklnr')
                         .gsub('-', '%')

          @terms = @terms.where(
            "term_norm ILIKE :q OR term_norm ILIKE :flex OR term ILIKE :flex",
            q: "%#{clean_q}%",
            flex: "%#{flex_q}%"
          ).order(
            Arel.sql("CASE
              WHEN term_norm = #{Sc03Dictionary::DicVocab.connection.quote(clean_q)} THEN 0
              WHEN term ILIKE #{Sc03Dictionary::DicVocab.connection.quote(@query)} THEN 1
              WHEN term_norm LIKE #{Sc03Dictionary::DicVocab.connection.quote(clean_q + '%')} THEN 2
              ELSE 3 END"),
            :term_norm
          ).limit(10)
        else
          # 2. BROWSE MODE (Kaminari is active here)
          @terms = @terms.order(:term_norm).page(params[:page]).per(10)
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