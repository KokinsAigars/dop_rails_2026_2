# app/controllers/dictionary/abbr/publication_sources_controller.rb
module Dictionary
  module Abbr
    class PublicationSourcesController < ApplicationController

      allow_unauthenticated_access only: %i[index show history]

      def index
        @per_page = 100
        @page = (params[:page] || 1).to_i
        offset = (@page - 1) * @per_page

        @records = Sc01Abbreviations::AbbrPublicationSource.where(is_current: true)

        if params[:q].present?
          q = "%#{params[:q]}%"
          @records = @records.where(
            "abbr_name ILIKE ? OR abbr_id_est ILIKE ? OR abbr_note ILIKE ? OR abbr_source_text ILIKE ?",
            q, q, q, q
          )
        end

        @total_count = @records.count
        @records = @records.order(:abbr_name).limit(@per_page).offset(offset)
      end

      def show
        @record = Sc01Abbreviations::AbbrPublicationSource.find(params[:id])
      end

      def history
        @record = Sc01Abbreviations::AbbrPublicationSource.find(params[:id])
        root_id = @record.root_id || @record.id
        @versions = Sc01Abbreviations::AbbrPublicationSource
                      .where(root_id: root_id).or(Sc01Abbreviations::AbbrPublicationSource.where(id: root_id))
                      .order(version: :desc)
      end
    end
  end
end
