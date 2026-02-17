# frozen_string_literal: true

class Api::V1::Ref::RefDocsController < Api::V1::BaseController
  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  MODEL = Sc02Bibliography::RefDoc

  # GET /api/v1/ref/ref_docs
  def index
    scope = MODEL.where(is_current: true).order(doc_title: :asc)
    scope = scope.where("doc_title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
    scope = scope.limit(limit_param)

    render json: scope.as_json(only: index_fields)
  end

  # GET /api/v1/ref/ref_docs/:id
  def show
    doc = MODEL.find(params[:id])
    render json: doc.as_json(only: show_fields)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  # POST /api/v1/ref/ref_docs
  def create
    doc = MODEL.new(permitted_params)
    doc.save!
    render json: doc.as_json(only: show_fields), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # PATCH /api/v1/ref/ref_docs/:id  (creates new version)
  def update
    set_db_audit_reason("ref_doc api update -> new version") if respond_to?(:set_db_audit_reason, true)

    doc = MODEL.find(params[:id])

    new_doc = doc.create_new_version!(
      attrs: permitted_params,
      modified_by: modified_by_for("api update -> new version")
    )

    render json: new_doc.as_json(only: show_fields), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # GET /api/v1/ref/ref_docs/:id/history
  def history
    doc = MODEL.find(params[:id])
    root_id = doc.root_id || doc.id

    versions = MODEL.where(root_id: root_id).or(MODEL.where(id: root_id))
                    .order(:version, :created_at)

    render json: versions.as_json(only: show_fields)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def index_fields
    %i[id doc_title revision created_at modified_date]
  end

  def show_fields
    %i[id doc_title doc_license doc_reference revision created_at modified_date modified_by root_id version is_current superseded_at superseded_by]
  end

  def permitted_params
    params.require(:ref_doc).permit(
      :doc_title,
      :doc_license,
      :revision,
      :revision_comment,
      doc_reference: {}
    )
  end

  def limit_param
    lim = params[:limit].to_i
    lim = 100 if lim <= 0
    [ lim, 500 ].min
  end
end
