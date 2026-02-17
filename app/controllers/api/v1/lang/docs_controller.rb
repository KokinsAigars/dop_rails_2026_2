# frozen_string_literal: true

class Api::V1::Lang::DocsController < Api::V1::BaseController
  MODEL = Sc04Language::LangDoc

  before_action -> { doorkeeper_authorize! :admin }, except: %i[show]

  def index
    scope = MODEL.order(doc_title: :asc)

    if params[:q].present?
      scope = scope.where("doc_title ILIKE ?", "%#{params[:q]}%")
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

  def update
    set_db_audit_reason("lang_doc api update") if respond_to?(:set_db_audit_reason, true)

    row = MODEL.find(params[:id])
    row.update!(permitted_params)
    render json: row, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  private

  def permitted_params
    params.require(:lang_doc).permit(
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
