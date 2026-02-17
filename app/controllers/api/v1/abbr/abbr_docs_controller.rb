# frozen_string_literal: true

class Api::V1::Abbr::AbbrDocsController < Api::V1::BaseController
  MODEL = Sc01Abbreviations::AbbrDoc

  # Policy: admin for all except show
  before_action -> { doorkeeper_authorize! :admin }, except: %i[show]

  # GET /api/v1/abbr/abbr_docs
  def index
    scope = MODEL.where(is_current: true).order(doc_title: :asc)

    if params[:q].present?
      scope = scope.where("doc_title ILIKE ?", "%#{params[:q]}%")
    end

    scope = scope.limit(limit_param)
    render json: scope
  end

  # GET /api/v1/abbr/abbr_docs/:id  (public)
  def show
    doc = MODEL.find(params[:id])
    render json: doc
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  # POST /api/v1/abbr/abbr_docs
  def create
    doc = MODEL.new(permitted_params)
    doc.save!
    render json: doc, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # PATCH /api/v1/abbr/abbr_docs/:id  (new version)
  def update
    set_db_audit_reason("abbr_doc api update -> new version") if respond_to?(:set_db_audit_reason, true)

    doc = MODEL.find(params[:id])

    new_doc = doc.create_new_version!(
      attrs: permitted_params,
      modified_by: modified_by_for("api update -> new version")
    )

    render json: new_doc, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # GET /api/v1/abbr/abbr_docs/:id/history
  def history
    doc = MODEL.find(params[:id])
    root_id = doc.root_id || doc.id

    versions = MODEL.where(root_id: root_id).or(MODEL.where(id: root_id))
                    .order(:version, :created_at)

    render json: versions
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def permitted_params
    params.require(:abbr_doc).permit(
      :doc_title,
      :doc_license,
      :revision,
      :revision_comment,
      doc_reference: {}
    )
  end

  def limit_param
    lim = params[:limit].to_i
    return 100 if lim <= 0
    [ lim, 500 ].min
  end
end
