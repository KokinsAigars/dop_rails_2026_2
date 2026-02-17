# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(only: nil, except: nil)
      skip_before_action :require_authentication, only: only, except: except
    end
  end

  private

  def require_admin!
    return if Current.user&.has_role?(:admin)

    redirect_to root_path, alert: "Not authorized"
  end

  def authenticated?
    # Current.user.present?
    resume_session && Current.user&.enabled? || terminate_and_redirect
  end

  def authenticated_user
    if session_record = Session.find_by(id: cookies.signed[:session_id])
      Current.session = session_record
      Current.user = session_record.user
    end
  end

  def terminate_and_redirect
    terminate_session if Current.session
    # redirect_to login_path...
  end

  def require_authentication
    request_authentication unless Current.user
  end

  def resume_session
    Current.session ||= find_session_by_cookie
    if Current.session&.revoked_at.present? # Extra safety check
      terminate_session
      nil
    else
      Current.session
    end
  end

  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) ||
      (Current.user&.has_role?(:admin) ? admin_root_path : account_root_path)
  end

  def start_new_session_for(user)
    user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
      expires_at: 24.hours.from_now
    ).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = {
        value: session.id,
        httponly: true,
        secure: Rails.env.production?, # Only send over HTTPS in production
        same_site: :lax
      }
    end
  end

  def terminate_session
    # 1. Destroy the DB record so the session is invalid server-side
    Current.session&.destroy

    # Forces the browser to clear it for the whole domain
    cookies.delete(:session_id, path: "/")

    Current.session = nil
    Current.user = nil
  end
end
