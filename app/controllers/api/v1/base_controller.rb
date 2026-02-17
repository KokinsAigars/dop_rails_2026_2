# frozen_string_literal: true

class Api::V1::BaseController < ActionController::API
  before_action :authorize_api!
  before_action :set_api_context

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: "not_found", details: e.message }, status: :not_found
  end


  private

  def authorize_api!
    doorkeeper_authorize!
  end

  # --- OAuth helpers ---
  def current_oauth_token
    doorkeeper_token
  end

  def current_oauth_application
    doorkeeper_token&.application
  end

  def current_api_user
    return nil unless doorkeeper_token&.resource_owner_id
    @current_api_user ||= User.find_by(id: doorkeeper_token.resource_owner_id)
  end

  # --- Context + audit wiring ---
  def set_api_context
    Current.oauth_token        = current_oauth_token
    Current.oauth_application  = current_oauth_application

    reason = request.headers["X-Change-Reason"].presence ||
             params[:revision_comment].presence ||
             "#{controller_name}##{action_name}"

    ActiveRecord::Base.connection.execute <<~SQL
    SELECT
      set_config('app.user_id', #{sql_str(current_api_user&.id)}, true),
      set_config('app.oauth_application_id', #{sql_str(current_oauth_application&.id)}, true),
      set_config('app.request_id', #{sql_str(request.request_id)}, true),
      set_config('app.ip', #{sql_str(request.remote_ip)}, true),
      set_config('app.user_agent', #{sql_str(request.user_agent)}, true),
      set_config('app.reason', #{sql_str(reason)}, true);
  SQL
  end


  # --- Helpers ---
  def sql_str(value)
    value.present? ? ActiveRecord::Base.connection.quote(value.to_s) : "NULL"
  end
end
