# frozen_string_literal: true

module DbAuditContext
  extend ActiveSupport::Concern

  included do
    before_action :set_db_audit_context
    after_action  :clear_db_audit_reason
  end

  private

  def set_db_audit_context
    user_id = Current.user&.id
    session_id = Current.session&.id

    oauth_app_id =
      if respond_to?(:doorkeeper_token, true)
        doorkeeper_token&.application_id
      end

    conn = ActiveRecord::Base.connection

    conn.execute("select set_config('app.user_id', #{conn.quote(user_id.to_s)}, true)")
    conn.execute("select set_config('app.session_id', #{conn.quote(session_id.to_s)}, true)")
    conn.execute("select set_config('app.oauth_application_id', #{conn.quote(oauth_app_id.to_s)}, true)")
    conn.execute("select set_config('app.request_id', #{conn.quote(request.request_id.to_s)}, true)")
    conn.execute("select set_config('app.ip', #{conn.quote(request.remote_ip.to_s)}, true)")
    conn.execute("select set_config('app.user_agent', #{conn.quote(request.user_agent.to_s)}, true)")
  end

  # Call this in actions to annotate triggers/audit rows
  def set_db_audit_reason(reason)
    conn = ActiveRecord::Base.connection
    conn.execute("select set_config('app.reason', #{conn.quote(reason.to_s)}, true)")
  end

  def clear_db_audit_reason
    conn = ActiveRecord::Base.connection
    conn.execute("select set_config('app.reason', '', true)")
  rescue StandardError
    # avoid masking controller response if connection isn't available
  end
end
