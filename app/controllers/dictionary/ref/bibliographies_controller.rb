# app/controllers/dictionary/ref/bibliographies_controller.rb
module Dictionary
  module Ref
    class BibliographiesController < ApplicationController

      allow_unauthenticated_access only: %i[index show history]

      def index
        @per_page = 50 # Bibliographies are "heavier" records
        @page = (params[:page] || 1).to_i
        offset = (@page - 1) * @per_page

        @records = Sc02Bibliography::RefBibliography.where(is_current: true)

        # Alphabetical filter
        @records = @records.where(ref_letter: params[:letter]) if params[:letter].present?

        # Search filter (Abbreviation or Title)
        if params[:q].present?
          q = "%#{params[:q]}%"
          @records = @records.where("ref_abbrev ILIKE ? OR ref_title ILIKE ? OR ref_author ILIKE ?", q, q, q)
        end

        @total_count = @records.count
        @records = @records.order(:ref_letter, :ref_abbrev, :ref_title).limit(@per_page).offset(offset)
      end

      def show
        @record = Sc02Bibliography::RefBibliography.find(params[:id])
      end

      def history
        @record = Sc02Bibliography::RefBibliography.find(params[:id])
        root_id = @record.root_id || @record.id
        @versions = Sc02Bibliography::RefBibliography
                      .where(root_id: root_id).or(Sc02Bibliography::RefBibliography.where(id: root_id))
                      .order(version: :desc)
      end
    end
  end
end

