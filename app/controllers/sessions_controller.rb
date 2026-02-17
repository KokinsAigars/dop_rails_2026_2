# frozen_string_literal: true

class SessionsController < ApplicationController
  # Stop bots at the door
  rate_limit to: 5, within: 1.minute, only: [ :verify_email, :verify_password ], with: -> {
    render json: { ok: false, error: "Too many attempts" }, status: :too_many_requests
  }

  before_action :check_if_not_already_logged_in, only: [ :index, :new, :create, :update ]
  allow_unauthenticated_access only: %i[ new create verify_email verify_password ]

  before_action :hide_header!
  before_action :hide_footer!

  # This allows the Stimulus controller to ping this action
  # even if the CSRF token hasn't fully "warmed up" yet.
  skip_before_action :require_authentication, only: [ :new, :create, :verify_email, :verify_password ]


  def index
    redirect_to login_path
  end

  def new
    check_if_not_already_logged_in
    session[:return_to] ||= params[:return_to] if params[:return_to].present?
    @user_name = params[:login]&.squish&.downcase
    @email = params[:email_address].to_s
  end

  def create
    # Check for the honeypot field 'user_Name'
    is_bot = params[:user_Name].present? || params[:userName].present? || params[:bot_intercepted] == true
    if is_bot
      log_bot_event("Bot trapped: Login Attempt")
      return render json: { status: "success", bot: true }, status: :ok
    end

    # FOR REAL HUMANS LOGIC STARTS HERE
    # authenticate_by returns the user if the password matches, or nil if not
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user
      if !user.enabled?
        redirect_to new_session_path, alert: "Account disabled. Contact support."
      elsif !user.verified?
        redirect_to new_session_path, alert: "Please verify your email first."
      else
        start_new_session_for user
        redirect_to after_authentication_url
      end
    else
      # Failed login (wrong email or wrong password)
      redirect_to new_session_path, alert: "Invalid email or password."
    end
  end

  def verify_email
    email = (params[:email_address] || params[:email]).to_s.strip.downcase
    puts(email)
    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return render json: { ok: false, error: "Invalid email format" }, status: :unprocessable_entity
    end
    user  = User.find_by(email_address: email)
    if user
      render json: { ok: true, email_address: email }
    else
      render json: { ok: false, error: "User not found" }, status: :not_found
    end
  end

  def verify_password
    email    = (params[:email_address] || params[:email]).to_s.strip.downcase
    password = params[:password].to_s
    user = User.find_by(email_address: email)

    if user.nil?
      return render json: { ok: false, error: "User not found" }, status: :not_found
    end

    unless user.enabled?
      return render json: { ok: false, error: "Account is disabled" }, status: :forbidden
    end

    if user
      if user.authenticate(password)
        start_new_session_for(user)
        user.update(last_sign_in_at: Time.current, last_sign_in_ip: request.remote_ip)
        notify("Welcome back, #{user.email_address}!", :success)
        target_path = user.admin? ? admin_root_path : account_root_path
        render json: { ok: true, redirect_to: target_path }
      else
        render json: { ok: false, error: "Invalid credentials" }, status: :unauthorized
      end
    else
      render json: { ok: false, error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.password_hash.present?
      redirect_to root_path
    elsif params[:user][:password].blank? || params[:user][:password_confirmation].blank?
      notify(I18n.t("users.notifications.set_new_password"), :error)
      render :edit
    elsif params[:user][:password] != params[:user][:password_confirmation]
      notify(I18n.t("users.notifications.password_and_confirmation_is_not_matching"), :error)
      render :edit
    else
      @user.set_password(params[:user][:password])
      notify(I18n.t("users.notifications.thanks_please_login"), :notice)
      redirect_to login_path(login: @user.email)
    end
  end

  def destroy
    # Don't check 'if current_user' for now—just run the termination
    terminate_session

    # Add a check to verify it actually cleared
    puts "DEBUG: Session ID after delete: #{cookies.signed[:session_id]}"

    notify("Signed out", :success)
    redirect_to root_path, status: :see_other
  end

  private

  def check_if_not_already_logged_in
    if current_user
      redirect_to root_path
    end
  end
end
