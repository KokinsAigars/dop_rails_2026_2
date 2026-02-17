# frozen_string_literal: true

class Api::V1::Hash::ExecutedSqlScriptsController < Api::V1::BaseController
  MODEL = Sc07Hash::ExecutedSqlScript

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.order(executed_at: :desc)
    scope = scope.limit(limit_param)
    render json: scope
  end

  # GET /api/v1/hash/executed_sql_scripts/lookup?file_hash=...
  def lookup
    hash = params.require(:file_hash).to_s.strip
    row = MODEL.find_by!(file_hash: hash)
    render json: row
  rescue ActiveRecord::RecordNotFound
    render json: { executed: false }, status: :ok
  end

  # POST /api/v1/hash/executed_sql_scripts
  # { "executed_sql_script": { "file_hash": "...", "file_path": "..." } }
  def create
    p = create_params

    row = {
      file_hash: p[:file_hash],
      file_path: p[:file_path],
      executed_at: Time.current
    }

    # Idempotent: if unique hash exists, do nothing / overwrite path if you want
    MODEL.upsert_all([ row ], unique_by: "uq_exec_sql_scripts_file_hash")

    render json: { recorded: true }, status: :created
  rescue ActionController::ParameterMissing => e
    render json: { error: "bad_request", details: e.message }, status: :bad_request
  end

  private

  def create_params
    params.require(:executed_sql_script).permit(:file_hash, :file_path).tap do |p|
      p.require(:file_hash)
    end.to_h.symbolize_keys
  end

  def limit_param
    lim = params[:limit].to_i
    return 50 if lim <= 0
    [ lim, 500 ].min
  end
end
