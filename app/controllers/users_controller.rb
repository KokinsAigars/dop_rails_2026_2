# frozen_string_literal: true

class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    # Caching bots
    if params[:user][:user_Name].present?
      # Pretend it worked so the bot doesn't try a different tactic
      return render json: { status: "success", bot: true }, status: :ok
    end

    @user = User.new(user_params)

    if @user.save
      render json: { status: "success", bot: false, location: root_path }
      # start_new_session_for(@user)   # logs in right after signup
      # redirect_to root_path, notice: "Welcome!"
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_settings
    # Using deep_merge ensures other settings keys aren't deleted
    new_settings = current_user.settings.deep_merge(params[:user][:settings].permit!.to_h)

    if current_user.update(settings: new_settings)
      redirect_to settings_path, notice: "Preferences updated!"
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
