# app/controllers/dictionary/abbr/grammatical_terms_controller.rb
module Dictionary
  module Abbr
    class GrammaticalTermsController < ApplicationController
      def index
        @per_page = 100
        @page = (params[:page] || 1).to_i
        offset = (@page - 1) * @per_page

        @records = Sc01Abbreviations::AbbrGrammaticalTerm.where(is_current: true)

        # Filters
        @records = @records.where("abbr_name ILIKE ?", "#{params[:letter]}%") if params[:letter].present?
        @records = @records.where("abbr_name ILIKE ?", "%#{params[:q]}%") if params[:q].present?

        @total_count = @records.count
        @records = @records.order(:abbr_letter, :abbr_name).limit(@per_page).offset(offset)
      end

      def show
        @record = Sc01Abbreviations::AbbrGrammaticalTerm.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to abbr_grammatical_terms_path, alert: "Term not found."
      end
    end
  end
end
