# frozen_string_literal: true

class Api::V1::Ref::RefInternetSourcesController < Api::V1::BaseController
  MODEL = Sc02Bibliography::RefInternetSource

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.where(is_current: true).order(:ref_title, :ref_url)

    # lightweight search
    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.where("ref_title ILIKE ? OR ref_url ILIKE ?", q, q)
    end

    scope = scope.limit(limit_param)
    render json: scope
  end

  def show
    row = MODEL.find(params[:id])
    render json: row
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  def create
    row = MODEL.new(permitted_params)
    row.save!
    render json: row, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # Versioned update (creates new row)
  def update
    set_db_audit_reason("ref_internet_source api update -> new version") if respond_to?(:set_db_audit_reason, true)

    row = MODEL.find(params[:id])

    new_row = row.create_new_version!(
      attrs: permitted_params,
      modified_by: modified_by_for("api update -> new version")
    )

    render json: new_row, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # GET /api/v1/ref/ref_internet_sources/:id/history
  # Returns all versions for this root_id (or just itself if no root_id)
  def history
    row = MODEL.find(params[:id])
    root_id = row.root_id || row.id

    versions = MODEL.where(root_id: root_id).or(MODEL.where(id: root_id))
                    .order(:version, :created_at)

    render json: versions
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def permitted_params
    params.require(:ref_internet_source).permit(
      :ref_title,
      :ref_url,
      :revision,
      :revision_comment
    )
  end

  def limit_param
    lim = params[:limit].to_i
    return 50 if lim <= 0
    [ lim, 200 ].min
  end
end
