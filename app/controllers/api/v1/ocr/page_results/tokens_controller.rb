# frozen_string_literal: true

class Api::V1::Ocr::PageResults::TokensController < Api::V1::BaseController
  TOKEN_MODEL = Sc06Ocr::OcrToken
  PAGE_RESULT_MODEL = Sc06Ocr::OcrPageResult

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])

    tokens = page_result.ocr_tokens
                        .order(:token_no, :created_at)

    render json: tokens
  end

  def show
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])

    token = page_result.ocr_tokens.find(params[:id])
    render json: token
  end

  def create
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])

    token = page_result.ocr_tokens.new(token_params)

    # if you use audit context like earlier:
    # set_db_audit_reason("ocr_token api create")
    token.save!

    render json: token, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # Bulk insert: faster for OCR pipelines
  # POST .../tokens/bulk_create
  # { "tokens": [ {token_no: 0, text: "...", text_norm: "...", bbox: {...}, confidence: 99.12, kind: "word"}, ... ] }
  def bulk_create
    page_result_id = params[:page_result_id]
    PAGE_RESULT_MODEL.find(page_result_id) # ensure it exists

    rows = bulk_tokens_params.map do |h|
      {
        fk_page_result_id: page_result_id,
        token_no: h[:token_no],
        text: h[:text],
        text_norm: h[:text_norm],
        bbox: h[:bbox] || {},
        confidence: h[:confidence],
        kind: h[:kind],

        revision: false,
        revision_comment: nil,

        created_at: Time.current,
        modified_date: Time.current,
        modified_by: nil
      }
    end

    if rows.empty?
      return render json: { error: "no_tokens" }, status: :unprocessable_entity
    end

    # DB constraints are the truth; insert_all skips model validations (fast path).
    # If you want validations, loop with create!, but it will be much slower.
    result = TOKEN_MODEL.insert_all(rows)

    render json: { inserted: rows.size, result: result.rows.size }, status: :created
  rescue ActionController::ParameterMissing => e
    render json: { error: "bad_request", details: e.message }, status: :bad_request
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found", details: "page_result not found" }, status: :not_found
  end

  private

  def token_params
    params.require(:ocr_token).permit(
      :token_no,
      :text,
      :text_norm,
      :confidence,
      :kind,
      bbox: {}
    )
  end

  def bulk_tokens_params
    params.require(:tokens).map do |t|
      ActionController::Parameters.new(t).permit(
        :token_no,
        :text,
        :text_norm,
        :confidence,
        :kind,
        bbox: {}
      ).to_h.symbolize_keys
    end
  end
end
