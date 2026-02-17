# frozen_string_literal: true

module Admin
  module Management
    class OauthApplicationsController < Admin::BaseController

      def index
        @keys = Doorkeeper::Application.order(created_at: :desc)

        respond_to do |format|
          format.html { render "admin/management/workspace/index" }
          format.json do
            render json: {
              explorer_title: "SECURITY KEYS",
              explorer_html: render_to_string(
                partial: "admin/management/oauth_applications/keys_list",
                locals: { keys: @keys }, # Passing 'keys' to the list
                formats: [:html]
              ),
              edit_html: render_to_string(
                partial: "admin/management/oauth_applications/keys_overview",
                locals: { keys: @keys }, # Ensure this partial doesn't use 'app'
                formats: [:html]
              )
            }
          end
        end
      end

      def show
        @app = Doorkeeper::Application.find(params[:id])
        respond_to do |format|
          format.html do
            render partial: "admin/management/oauth_applications/show_fragment",
                   locals: { app: @app } # Handing @app over as 'app'
          end
        end
      end







      def new
        @app = Doorkeeper::Application.new
        render partial: "form", locals: { app: @app }
      end

      def create
        @app = Doorkeeper::Application.new(app_params)

        @app.confidential = true if @app.confidential.nil?

        if @app.save
          notify("Application created. Copy the secret now (shown below).", :notice)
          redirect_to admin_oauth_application_path(@app)
        else
          render :new, status: :unprocessable_entity
        end
      end


      def rotate_secret
        @app = Doorkeeper::Application.find(params[:id])

        # Doorkeeper provides renew_secret for rotating client secrets
        @app.renew_secret

        if @app.save
          notify("Secret rotated. Copy the new secret now (shown below).", :notice)
          redirect_to admin_oauth_application_path(@app)
        else
          notify_now("Failed to rotate secret.", :alert)
          redirect_to admin_oauth_application_path(@app)
        end
      end

      def destroy
        @app = Doorkeeper::Application.find(params[:id])
        @app.destroy!
        redirect_to admin_oauth_applications_path, notice: "Application deleted"
      end

      def revoke_tokens
        @app = Doorkeeper::Application.find(params[:id])
        Doorkeeper::AccessToken.where(application_id: @app.id, revoked_at: nil)
                               .update_all(revoked_at: Time.current)

        redirect_to admin_oauth_application_path(@app), notice: "Active tokens revoked"
      end

      private

      def app_params
        # scopes is a space-separated string in Doorkeeper apps
        params.require(:doorkeeper_application).permit(:name, :scopes, :redirect_uri, :confidential)
      end
    end
  end
end


# urn:ietf:wg:oauth:2.0:oob
