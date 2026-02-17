# frozen_string_literal: true

class Api::V1::Abbr::AbbrGeneralTermsController < Api::V1::BaseController
  MODEL = Sc01Abbreviations::AbbrGeneralTerm

  # Policy: everything admin-only except show
  before_action -> { doorkeeper_authorize! :admin }, except: %i[show]

  # GET /api/v1/abbr/abbr_general_terms
  def index
    scope = MODEL.where(is_current: true).order(:abbr_letter, :abbr_name)

    scope = scope.where(abbr_letter: params[:letter]) if params[:letter].present?

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.where(
        "abbr_name ILIKE ? OR abbr_lv ILIKE ? OR abbr_id_est ILIKE ? OR abbr_source ILIKE ?",
        q, q, q, q
      )
    end

    scope = scope.limit(limit_param)
    render json: scope
  end

  # GET /api/v1/abbr/abbr_general_terms/:id  (public)
  def show
    row = MODEL.find(params[:id])
    render json: row
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  # POST /api/v1/abbr/abbr_general_terms
  def create
    row = MODEL.new(permitted_params)
    row.save!
    render json: row, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # PATCH /api/v1/abbr/abbr_general_terms/:id  (new version)
  def update
    set_db_audit_reason("abbr_general_terms api update -> new version") if respond_to?(:set_db_audit_reason, true)

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

  # GET /api/v1/abbr/abbr_general_terms/:id/history
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
    params.require(:abbr_general_term).permit(
      :abbr_letter,
      :abbr_name,
      :abbr_id_est,
      :abbr_lv,
      :abbr_ref_id,
      :abbr_note,
      :abbr_source,
      :abbr_source_text,
      :revision,
      :revision_comment
    )
  end

  def limit_param
    lim = params[:limit].to_i
    return 100 if lim <= 0
    [ lim, 500 ].min
  end
end
