# frozen_string_literal: true

module Dictionary
  module Abbr
    class GeneralTermsController < ApplicationController
      # Publicly accessible index and show

      def index
        @per_page = 100
        @page = (params[:page] || 1).to_i
        offset = (@page - 1) * @per_page

        @records = Sc01Abbreviations::AbbrGeneralTerm.where(is_current: true)

        # A-Z Filter
        if params[:letter].present?
          @records = @records.where("abbr_name ILIKE ?", "#{params[:letter]}%")
        end

        # Search Filter
        if params[:q].present?
          @records = @records.where("abbr_name ILIKE ?", "%#{params[:q]}%")
        end

        @total_count = @records.count
        @records = @records.order(:abbr_letter, :abbr_name).limit(@per_page).offset(offset)
      end

      def show
        @record = Sc01Abbreviations::AbbrGeneralTerm.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to abbr_general_terms_path, alert: "Record not found."
      end
    end
  end
end

