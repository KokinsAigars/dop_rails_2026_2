# frozen_string_literal: true

class UserMailer < ApplicationMailer
  # Use the email Resend gave you, or your verified domain
  default from: "onboarding@resend.dev"


  def email_verification(user)
    @user = user
    # This generates a secure string containing the user ID and an expiration date.
    # It cannot be tampered with because it's signed with your Rails Master Key.
    @token = user.signed_id(purpose: :email_verification, expires_in: 24.hours)

    mail(
      to: @user.email_address,
      subject: "Verify your account"
    )
  end
end
