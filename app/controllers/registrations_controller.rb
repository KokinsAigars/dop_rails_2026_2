# frozen_string_literal: true

class RegistrationsController < ApplicationController
  # Allow them to see the sign-up form!
  allow_unauthenticated_access only: [ :new, :create, :sent, :check_email, :verification_sent, :verify ]

  before_action :hide_header!, :hide_footer!

  def new
    @user = User.new
  end

  def create
    # Check for the honeypot field 'user_Name'
    is_bot = params[:user_Name].present? || params[:userName].present? || params[:bot_intercepted] == true
    if is_bot
      log_bot_event("Bot trapped in Registration Flow")
      return render json: { status: "success", bot: true }, status: :ok
    end

    # FOR REAL HUMANS LOGIC STARTS HERE
    @user = User.new(user_params)

    if @user.save
      # 1. Generate the verification token (expires in 24 hours)
      # 2. Send the email
      # .deliver_later sends it in the background so the user doesn't wait
      UserMailer.email_verification(@user).deliver_later

      render json: {
        ok: true,
        status: "success",
        message: "Check your email!",
        location: "/registration_verification_sent" # A static info page
      }, status: :created
    else
      render json: {  ok: false, errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def sent
  end

  def check_email
    # If the bot somehow includes the honeypot field in this request
    if params[:user_Name].present?
      render json: { available: false, message: "Bot detected" }, status: :ok
      return
    end

    exists = User.exists?(email_address: params[:email].to_s.strip.downcase)
    render json: { available: !exists, message: exists ? "Email already taken" : "Success" }
  end

  def verify
    user = User.find_signed!(params[:token], purpose: :email_verification)

    if user.verified?
      redirect_to root_path, notice: "You are already verified! Please log in."
    elsif user.verify!
      start_new_session_for user
      redirect_to root_path, notice: "Welcome! Your email is verified."
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    # If the token was tampered with or expired, this error is raised.
    redirect_to new_registration_path, alert: "The link is invalid or has expired."
  end

  def verification_sent
    # Just renders the view
  end

  private

  def user_params
    # Do NOT add :user_Name here. We want to keep it out of the DB.
    params.require(:user).permit(:first_name, :last_name, :email_address, :password, :password_confirmation)
  end
end
