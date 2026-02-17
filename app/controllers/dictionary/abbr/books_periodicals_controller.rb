# frozen_string_literal: true

module Dictionary
  module Abbr
    class BooksPeriodicalsController < ApplicationController
      allow_unauthenticated_access only: %i[index show]

      def index
        # 1. Start the scope
        scope = Sc01Abbreviations::AbbrBooksPeriodical.where(is_current: true)

        # 2. Apply Filters
        scope = scope.where("abbr_name ILIKE ?", "#{params[:letter]}%") if params[:letter].present?
        scope = scope.where("abbr_name ILIKE ?", "%#{params[:q]}%") if params[:q].present?

        # 3. Apply Kaminari (This is where the magic happens)
        # .page(params[:page]) triggers the pagination logic
        # .per(25) overrides the default config if needed
        @records = scope.order(:abbr_name).page(params[:page]).per(25)
      end



      def show
        # We use find_by to avoid a hard crash if the ID is malformed or missing
        @record = Sc01Abbreviations::AbbrBooksPeriodical.find_by(id: params[:id])

        if @record.nil?
          redirect_to abbr_books_periodicals_path, alert: "Record not found."
        end
      end



    end
  end
end