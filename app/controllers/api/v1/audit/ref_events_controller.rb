# frozen_string_literal: true

class Api::V1::Audit::RefEventsController < Api::V1::BaseController
  MODEL = Sc05Audit::RefAuditEvent

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.order(event_at: :desc)

    scope = scope.where(table_name: params[:table_name]) if params[:table_name].present?
    scope = scope.where(row_id: params[:row_id]) if params[:row_id].present?
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(session_id: params[:session_id]) if params[:session_id].present?
    scope = scope.where(request_id: params[:request_id]) if params[:request_id].present?
    scope = scope.where(action: params[:action]) if params[:action].present?

    if params[:since].present?
      scope = scope.where("event_at >= ?", Time.iso8601(params[:since]))
    end

    scope = scope.limit(limit_param)
    render json: scope
  rescue ArgumentError
    render json: { error: "bad_request", details: "invalid since timestamp" }, status: :bad_request
  end

  def show
    render json: MODEL.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def limit_param
    lim = params[:limit].to_i
    return 50 if lim <= 0
    [ lim, 500 ].min
  end
end
