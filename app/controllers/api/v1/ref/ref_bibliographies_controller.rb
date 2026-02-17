# frozen_string_literal: true

class Api::V1::Ref::RefBibliographiesController < Api::V1::BaseController
  MODEL = Sc02Bibliography::RefBibliography

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.where(is_current: true).order(:ref_letter, :ref_abbrev, :ref_title)

    # useful filters
    scope = scope.where(ref_letter: params[:ref_letter]) if params[:ref_letter].present?
    scope = scope.where("ref_abbrev ILIKE ?", "%#{params[:q]}%").or(scope.where("ref_title ILIKE ?", "%#{params[:q]}%")) if params[:q].present?

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

    # if you use audit context reasons
    # set_db_audit_reason("ref_bibliography api create")

    row.save!

    render json: row, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # Update should create a NEW VERSION row (VersionedEntry)
  def update
    set_db_audit_reason("ref_bibliography api update -> new version") if respond_to?(:set_db_audit_reason, true)

    @row = MODEL.find(params[:id])

    # You used this pattern earlier:
    new_row = @row.create_new_version!(
      attrs: permitted_params,
      modified_by: modified_by_for("api update -> new version")
    )

    render json: new_row, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  private

  def permitted_params
    params.require(:ref_bibliography).permit(
      :ref_letter,
      :ref_abbrev,
      :ref_title,
      :ref_note,
      :ref_citation,
      :ref_footnote,
      :ref_publisher,
      :ref_place,
      :ref_volume,
      :ref_part,
      :ref_type,
      :ref_author,
      :ref_url,
      :ref_ref1,
      :ref_ref2,
      :ref_title_lv,
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
