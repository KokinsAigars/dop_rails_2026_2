# frozen_string_literal: true

class Api::V1::Hash::TemporaryHashController < Api::V1::BaseController
  MODEL = Sc07Hash::TemporaryHash

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.order(:fk_index_id)
    scope = scope.limit(limit_param)
    render json: scope
  end

  # GET /api/v1/hash/temporary_hash/lookup?hex=...
  def lookup
    hex = params.require(:hex).to_s.strip
    bytes = [ hex ].pack("H*")

    row = MODEL.find_by!(dic_index_hash: bytes)
    render json: row
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  rescue ArgumentError
    render json: { error: "bad_request", details: "invalid hex" }, status: :bad_request
  end

  # POST /api/v1/hash/temporary_hash
  # { "temporary_hash": { "hex": "...", "fk_index_id": "..." } }
  def create
    p = create_params

    row = {
      dic_index_hash: [ p[:hex] ].pack("H*"),
      fk_index_id: p[:fk_index_id]
    }

    # If you have unique index on dic_index_hash, this is perfect:
    MODEL.upsert_all([ row ], unique_by: "uq_tmp_hash_dic_index_hash")

    render json: { upserted: 1 }, status: :created
  rescue ActionController::ParameterMissing => e
    render json: { error: "bad_request", details: e.message }, status: :bad_request
  rescue ArgumentError
    render json: { error: "bad_request", details: "invalid hex" }, status: :bad_request
  end

  # POST /api/v1/hash/temporary_hash/bulk_upsert
  # { "rows": [ {"hex":"...", "fk_index_id":"..."}, ... ] }
  def bulk_upsert
    rows = params.require(:rows)
    unless rows.is_a?(Array)
      raise ActionController::ParameterMissing, "rows must be an array"
    end

    mapped = rows.map do |r|
      h = ActionController::Parameters.new(r).permit(:hex, :fk_index_id).to_h
      {
        dic_index_hash: [ h.fetch("hex") ].pack("H*"),
        fk_index_id: h.fetch("fk_index_id")
      }
    end

    return render json: { upserted: 0 }, status: :ok if mapped.empty?

    MODEL.upsert_all(mapped, unique_by: "uq_tmp_hash_dic_index_hash")

    render json: { upserted: mapped.size }, status: :created
  rescue ActionController::ParameterMissing => e
    render json: { error: "bad_request", details: e.message }, status: :bad_request
  rescue ArgumentError, KeyError
    render json: { error: "bad_request", details: "invalid payload or hex" }, status: :bad_request
  end

  # DELETE /api/v1/hash/temporary_hash/truncate
  def truncate
    # Fast reset for pipeline runs
    MODEL.delete_all
    render json: { deleted: true }, status: :ok
  end

  private

  def create_params
    params.require(:temporary_hash).permit(:hex, :fk_index_id).tap do |p|
      p.require(:hex)
      p.require(:fk_index_id)
    end.to_h.symbolize_keys
  end

  def limit_param
    lim = params[:limit].to_i
    return 50 if lim <= 0
    [ lim, 500 ].min
  end
end
