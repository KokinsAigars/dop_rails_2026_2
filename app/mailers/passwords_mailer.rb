# frozen_string_literal: true

class PasswordsMailer < ApplicationMailer
  def reset(user, token)
    @user = user
    # @token = user.generate_password_reset_token
    @token = token # token in generate in password_controller create
    mail(
      to: @user.email_address,
      from: "onboarding@resend.dev",
      subject: t("passwords.mailer_subject")
    )
  end
end


#
# bin/rails c
# token = "eyJfcmFpbHMiOnsiZGF0YSI6WyJiYjlkYjMwMS1mMjRhLTRiMDMtYTZiZC0xNmNlMzdkYTI1YjgiLCJRbVEudXZmQWhPIl0sImV4cCI6IjIwMjYtMDItMDVUMTk6NDQ6MzAuNTQ4WiIsInB1ciI6IlVzZXJcbnBhc3N3b3JkX3Jlc2V0XG45MDAifX0=--124773372153f8b5c005738befe27e362ebb0f48"
# User.find_signed(token, purpose: "reset")


# # 1. Grab a user
# u = User.first
#
# # 2. Generate a token manually
# token = user.signed_id(purpose: "reset", expires_in: 1.hour)
#
# # 3. Try to find them immediately
# User.find_signed(token, purpose: "reset")
#
