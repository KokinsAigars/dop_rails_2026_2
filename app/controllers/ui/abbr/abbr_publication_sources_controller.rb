# frozen_string_literal: true

module Ui
  module Abbr
    class AbbrPublicationSourcesController < ApplicationController
      allow_unauthenticated_access only: %i[index show]

      before_action :set_row, only: %i[show edit update]
      before_action :require_authenticated_user!, only: %i[new create edit update]
      before_action :require_admin!, only: %i[destroy]

      def index
        @rows = Sc01Abbreviations::AbbrPublicationSource
                  .current
                  .order(:abbr_name)
                  .limit(500)
      end

      def show
      end

      def new
        @row = Sc01Abbreviations::AbbrPublicationSource.new
      end

      def create
        set_db_audit_reason("abbr_publication_sources ui create")
        @row = Sc01Abbreviations::AbbrPublicationSource.new(permitted_params)
        @row.modified_by = modified_by_for("ui create")

        if @row.save
          redirect_to ui_abbr_abbr_publication_source_path(@row, locale: I18n.locale), notice: "Created"
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        set_db_audit_reason("abbr_publication_sources ui update -> new version")

        new_row = @row.create_new_version!(
          attrs: permitted_params,
          modified_by: modified_by_for("ui update -> new version")
        )

        redirect_to ui_abbr_abbr_publication_source_path([ :ui, :abbr, new_row ], locale: I18n.locale),
                    notice: "Updated (new version created)"
      rescue ActiveRecord::RecordInvalid => e
        @row = e.record
        render :edit, status: :unprocessable_entity
      end

      def destroy
        set_db_audit_reason("abbr_publication_sources ui destroy")
        @row.destroy!
        redirect_to ui_abbr_abbr_publication_source_path(locale: I18n.locale), notice: "Deleted"
      end


      private

      def set_row
        @row = Sc01Abbreviations::AbbrPublicationSource.find(params[:id])
      end

      def permitted_params
        params.require(:abbr_publication_source).permit(
          :abbr_name, :abbr_id_est, :abbr_note, :abbr_source_text, :abbr_citation, :revision
        )
      end

      def modified_by_for(reason)
        return unless Current.user

        {
          actor: {
            type: "user",
            user_id: Current.user.id,
            email: Current.user.email_address
          },
          source: { app: "rails-ui" },
          change: { reason: reason }
        }
      end
    end
  end
end
