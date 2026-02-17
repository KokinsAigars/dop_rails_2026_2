# app/controllers/dictionary/ref/texts_controller.rb
module Dictionary
  module Ref
    class TextsController < ApplicationController
      def index
        @per_page = 50
        @page = (params[:page] || 1).to_i
        offset = (@page - 1) * @per_page

        @records = Sc02Bibliography::RefText.where(is_current: true)

        # Specialized Filters
        @records = @records.where(ref_texts_lang: params[:lang]) if params[:lang].present?

        if params[:q].present?
          q = "%#{params[:q]}%"
          @records = @records.where(
            "ref_texts_title ILIKE ? OR ref_title ILIKE ? OR ref_abbrev ILIKE ?",
            q, q, q
          )
        end

        @total_count = @records.count
        @records = @records.order(Arel.sql("NULLIF(regexp_replace(ref_texts_no, '\D', '', 'g'), '')::int ASC, ref_texts_no ASC"))
                           .limit(@per_page).offset(offset)

        # Get unique languages for the filter dropdown
        @languages = Sc02Bibliography::RefText.where.not(ref_texts_lang: nil)
                                              .distinct.pluck(:ref_texts_lang)
      end

      def show
        @record = Sc02Bibliography::RefText.find(params[:id])
      end
    end
  end
end