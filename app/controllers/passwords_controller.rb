# frozen_string_literal: true

class PasswordsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create, :sent, :edit, :update ]
  # We use the filter to catch bad tokens before any method runs
  before_action :set_user_by_token, only: [ :edit, :update ]

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_password_path, alert: t("passwords.rate_limit_error")
  }

  before_action :hide_header!
  before_action :hide_footer!

  def new
  end

  def create
    # Check for the honeypot field 'user_Name'
    is_bot = params[:user_Name].present? || params[:userName].present? || params[:bot_intercepted] == true
    if is_bot
      log_bot_event("Bot trapped: Password Request (Step 0)")
      return render json: { status: "success", bot: true }, status: :ok
    end

    # FOR REAL HUMANS LOGIC STARTS HERE
    # 1. Explicit Extraction
    # Using .to_s.downcase ensures we don't get 'nil' errors or case-sensitivity bugs
    email_input = params[:email_address].to_s.strip.downcase

    # 2. Manual Lookup
    user = User.find_by(email_address: email_input)

    if user
      # 3. Explicit Token Generation
      # Instead of letting the Mailer or Model handle it, we set it here.
      # SecureRandom.urlsafe_base64 creates a clean string like 'ZwIaDyf1bDcEwE9FqUdaQQ'
      new_token = SecureRandom.urlsafe_base64

      # We use update_columns to bypass all those hidden "has_secure_password" checks
      user.update_columns(
        reset_password_token: new_token,
        reset_password_sent_at: Time.current
      )

      # 4. Explicit Delivery
      # We pass the user AND the token explicitly so the mailer doesn't have to "guess"
      PasswordsMailer.reset(user, new_token).deliver_now
      puts "SUCCESS: Reset email sent to #{email_input} with token #{new_token}"

      # Puts in terminal, no need to go to check e-mail
      puts "--------------------------------------------------------"
      puts "PASSWORD RESET LINK: http://localhost:3000/passwords/#{new_token}/edit"
      puts "--------------------------------------------------------"

    else
      # We log this for your eyes only, but don't tell the UI (Security)
      puts "NOTICE: Reset requested for non-existent email: #{email_input}"
    end

    # 5. The Response
    # Always returning 200 OK prevents 'User Enumeration' (hackers checking if emails exist)
    render json: { ok: true, message: "If that email exists, instructions are on the way." }, status: :ok

  rescue => e
    # The Safety Net
    puts "FATAL ERROR IN PASSWORDS#CREATE: #{e.class} - #{e.message}"
    render json: { ok: false, error: "Internal Server Error" }, status: :internal_server_error
  end

  def sent
    # This page just says, "Check your email."
  end

  def edit
    # @user is already set by before_action
    # Render edit.html.erb
  end

  def update
    # Check for the honeypot field 'user_Name'
    is_bot = params[:user_Name].present? || params[:userName].present? || params[:bot_intercepted] == true
    if is_bot
      log_bot_event("Bot trapped: Password Update (Step 1)")
      return render json: { status: "success", bot: true }, status: :ok
    end

    # FOR REAL HUMANS LOGIC STARTS HERE
    # 1. MANUALLY find the user (No more hidden set_user_by_token)
    # params[:token] comes from the URL: /passwords/XYZ-TOKEN-HERE
    @user = User.find_by(reset_password_token: params[:token])

    # 2. EXPLICIT check for existence and time
    # If the user is missing OR token is older than 2 hours...
    if @user.nil? || @user.reset_password_sent_at < 2.hours.ago
      notify(t("passwords.invalid_token"), :alert)
      redirect_to new_password_path and return
      return # STOP HERE
    end

    # 3. EXTRACT the string from the form
    # params[:user][:password] is just a nested dictionary/hash
    new_password = params[:user][:password]

    # 4. VALIDATE manually
    if new_password.blank? || new_password.length < 8
      # If we fail, we re-render the edit page.
      # Since we set @user manually above, the form in edit.html.erb will still work.
      notify_now("Password too short.", :alert)
      render :edit, status: :unprocessable_entity
      return
    end

    # 5. DATABASE UPDATE (The raw way)
    # We hash the string manually and shove it into the column.
    # This ignores confirmation requirements and model "magic."
    hashed_string = BCrypt::Password.create(new_password)

    success = @user.update_columns(
      password_digest: hashed_string,
      reset_password_token: nil, # Clear the token so it's a "one-time use" link
      reset_password_sent_at: nil
    )

    # 6. THE FORK IN THE ROAD (Explicit Fallback)
    if success
      notify(t("passwords.reset_success"), :success)
      redirect_to new_session_path and return
    else
      notify(t("passwords.database_failed"), :alert)
      render :edit, status: :unprocessable_entity
    end

    # IN RAILS WAY
    # @user.password_confirmation = password_params[:password]
    # if @user.save
    #   @user.update!(reset_password_token: nil, reset_password_sent_at: nil)
    #   redirect_to new_session_path, notice: t("passwords.reset_success")
    # else
    #   render :edit, status: :unprocessable_entity
    # end
  end

  private

  def set_user_by_token
    @user = User.find_by(reset_password_token: params[:token])
    if @user.nil? || @user.reset_password_sent_at < 2.hours.ago
      notify(t("passwords.invalid_token"), :alert)
      redirect_to new_password_path and return
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
