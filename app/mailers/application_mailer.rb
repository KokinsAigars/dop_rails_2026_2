# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # default from: ENV.fetch("MAIL_FROM", "no-reply@example.com")
  default from: "no-reply@yourverifieddomain.com"
  layout "mailer"
end
