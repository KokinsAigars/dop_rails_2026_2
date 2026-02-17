# app/controllers/dictionary/dic/vocab_controller.rb
module Dictionary
  module Dic
    class VocabController < ApplicationController
      def index
        @lang = params[:lang] || 'pi'
        @query = params[:q]

        # Simple fetch to verify DB connection
        @terms = Sc03Dictionary::DicVocab.where(lang: @lang)

        if @query.present?
          @terms = @terms.where("term_norm ILIKE ?", "#{@query.downcase}%")
        end

        @terms = @terms.order(:term_norm).limit(100)
      end
    end
  end
end