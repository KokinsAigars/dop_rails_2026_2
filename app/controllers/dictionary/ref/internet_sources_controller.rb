# app/controllers/dictionary/ref/internet_sources_controller.rb
module Dictionary
  module Ref
    class InternetSourcesController < ApplicationController
      def index
        @per_page = 100
        @page = (params[:page] || 1).to_i
        offset = (@page - 1) * @per_page

        @records = Sc02Bibliography::RefInternetSource.where(is_current: true)

        if params[:q].present?
          q = "%#{params[:q]}%"
          @records = @records.where("ref_title ILIKE ? OR ref_url ILIKE ?", q, q)
        end

        @total_count = @records.count
        @records = @records.order(:ref_title).limit(@per_page).offset(offset)
      end

      def show
        @record = Sc02Bibliography::RefInternetSource.find(params[:id])
      end
    end
  end
end
