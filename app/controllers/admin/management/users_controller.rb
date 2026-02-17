# frozen_string_literal: true

module Admin
  module Management
    class UsersController < Admin::BaseController
      # just for debugging purposes; test function calls in the console
      # set to false if not using the logger console for debugging
      #
      # @!attribute [rw] debug_mode
      #   @return [Boolean] Toggle for verbose console/log output. Defaults to true.
      class_attribute :debug_mode, default: true


      before_action :set_user,  only: %i[show edit update destroy]
      before_action :load_roles, only: %i[new create edit update]
      before_action :prevent_self_disable, only: :update

      def index
        @users = User.all
        @admins = @users.select { |u| u.roles.any? { |r| r.name == "admin" } }

        respond_to do |format|
          format.html { render "admin/management/users/index" }
          format.json {
            render_workspace(
              title: "SYSTEM USERS",
              explorer_partial: "admin/management/users/explorer_list",
              edit_partial: "admin/management/users/stats",
              locals: { users: @users, admins: @admins } # pass whatever you need
            )
          }
        end
      end



      def edit
        # @user is already loaded by before_action :set_user
        load_roles

        respond_to do |format|
          # This handles the Stimulus fetch request
          format.html { render partial: "form", locals: { user: @user } }
        end
      end


      def show
        @user = User.find(params[:id])
      end

      def new
        @user = User.new
      end

      def create
        @user = User.new(user_params)
        if @user.save
          assign_roles!(@user)
          notify(t("users.notifications.created"), :success)
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: [
                # 1. Add the new user to the top of the list in the sidebar
                turbo_stream.prepend("explorer-user-list", partial: "admin/users/explorer_item", locals: { user: @user }),
                # 2. Show the new user's profile in the center
                turbo_stream.update("main_content", template: "admin/users/show")
              ]
            end
            format.html { redirect_to admin_user_path(@user) }
          end
        else
          render :new, status: :unprocessable_entity
        end
      end



      def update
        # Wrap in transaction to ensure user data and roles save together
        ActiveRecord::Base.transaction do
          if @user.update(user_params)
            assign_roles!(@user)
            notify(t("users.notifications.updated"), :success)
            redirect_to admin_user_path(@user)
          else
            # Error handled by render below
            raise ActiveRecord::Rollback
          end
        end
      rescue ActiveRecord::Rollback
        load_roles
        render :edit, status: :unprocessable_entity
      end

      def destroy
        if @user == Current.user
          notify(t("users.notifications.self_delete_error"), :error)
          redirect_to admin_users_path and return
        end

        if @user.roles.exists?(name: "admin") &&
           User.joins(:roles).where(roles: { name: "admin" }).distinct.count == 1
          notify(t("users.notifications.last_admin_delete_error"), :error)
          redirect_to admin_users_path and return
          return
        end

        if @user.destroy
          notify(t("users.notifications.deleted"), :success)
          redirect_to admin_users_path
        else
          notify(t("users.notifications.delete_failed"), :error)
          redirect_back fallback_location: admin_user_path(@user)
        end
      end

      private


      def user_params
        # 1. Look at the RAW params first
        private_debug("RAW PARAMS: #{params.inspect}")

        permitted = params.require(:user).permit(
          :email_address,
          :first_name,
          :last_name,
          :enabled,
          :password,
          :password_confirmation,
          :locale
        )

        private_debug("SAFE PARAMS: #{permitted.to_h.inspect}")

        if params[:user].key?(:settings)
          raw = params[:user][:settings].to_s.strip
          permitted[:settings] = raw.present? ? JSON.parse(raw) : {}
        end

        if permitted[:password].blank? && permitted[:password_confirmation].blank?
          permitted.delete(:password)
          permitted.delete(:password_confirmation)
        end

        permitted
      rescue JSON::ParserError => e
        @user.errors.add(:settings, "must be valid JSON (#{e.message})")
        permitted.delete(:settings)
        permitted
      end

      def role_names_params
        Array(params.dig(:user, :role_names)).reject(&:blank?)
      end

      def prevent_self_disable
        return unless @user == Current.user
        enabled_param = params.dig(:user, :enabled)
        return if enabled_param.nil?

        if ActiveModel::Type::Boolean.new.cast(enabled_param) == false
          notify("Self-disabling is locked for security.", :error)
          redirect_to edit_admin_user_path(@user) and return
        end
      end

      def set_user
        @user = User.find(params[:id])
      end

      def load_roles
        @roles = Role.order(:name)
      end

      def assign_roles!(user)
        names = Array(params.dig(:user, :role_names)).reject(&:blank?)

        # PROTECTION: If I am editing MYSELF, and I was an admin,
        # don't let me remove the admin role.
        if user == Current.user && user.roles.exists?(name: "admin")
          names << "admin" unless names.include?("admin")
        end

        names = [ "user" ] if names.empty?
        user.roles = Role.where(name: names.uniq)
      end
    end
  end
end
