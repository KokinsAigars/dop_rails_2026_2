# frozen_string_literal: true

class Api::V1::Lang::LanguagesController < Api::V1::BaseController
  MODEL = Sc04Language::LangLanguage

  before_action -> { doorkeeper_authorize! :admin }, except: %i[show]

  def index
    scope = MODEL.order(:lang_title)

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.where(
        "lang_title ILIKE ? OR lang_language ILIKE ? OR lang_abbr ILIKE ? OR lang_code ILIKE ?",
        q, q, q, q
      )
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
    set_db_audit_reason("lang_language api update") if respond_to?(:set_db_audit_reason, true)

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
    params.require(:lang_language).permit(
      :lang_title,
      :lang_language,
      :lang_eng_equivalent,
      :lang_abbr,
      :lang_abbr2,
      :lang_url,
      :lang_alphabet,
      :lang_vowels,
      :lang_consonants,
      :lang_niggahita,
      :lang_code,
      :lang_code2,
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
