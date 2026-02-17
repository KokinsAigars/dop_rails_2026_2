# frozen_string_literal: true

class Api::V1::Ocr::PageResultsController < Api::V1::BaseController
  MODEL = Sc06Ocr::OcrPageResult

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.order(created_at: :desc)
    scope = scope.where(fk_run_id: params[:run_id]) if params[:run_id].present?
    scope = scope.where(fk_page_id: params[:page_id]) if params[:page_id].present?
    scope = scope.limit(limit_param)
    render json: scope
  end

  def show
    render json: MODEL.find(params[:id])
  end

  def full
    row = MODEL.includes(:ocr_tokens, :ocr_review, :ocr_links).find(params[:id])
    render json: row, include: { ocr_tokens: {}, ocr_review: {}, ocr_links: {} }
  end

  # POST /api/v1/ocr/page_results/:id/ingest
  # Payload (any subset is allowed):
  # {
  #   "mode": "replace",   // optional: "replace" (default) or "append"
  #   "tokens": [...],
  #   "review": {...},
  #   "links": [...]
  # }
  def ingest
    page_result = MODEL.find(params[:id])
    mode = (params[:mode].presence || "replace")

    now = Time.current

    ActiveRecord::Base.transaction do
      ingest_tokens!(page_result.id, now, mode)
      ingest_review!(page_result.id, now)
      ingest_links!(page_result.id, now, mode)
    end

    row = MODEL.includes(:ocr_tokens, :ocr_review, :ocr_links).find(page_result.id)
    render json: row, include: { ocr_tokens: {}, ocr_review: {}, ocr_links: {} }, status: :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: "bad_request", details: e.message }, status: :bad_request
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def ingest_tokens!(page_result_id, now, mode)
    return unless params.key?(:tokens)

    tokens = params.require(:tokens)
    unless tokens.is_a?(Array)
      raise ActionController::ParameterMissing, "tokens must be an array"
    end

    Sc06Ocr::OcrToken.where(fk_page_result_id: page_result_id).delete_all if mode == "replace"

    rows = tokens.map do |t|
      h = ActionController::Parameters.new(t).permit(
        :token_no, :text, :text_norm, :confidence, :kind,
        bbox: {}
      ).to_h

      {
        fk_page_result_id: page_result_id,
        token_no: h["token_no"],
        text: h["text"],
        text_norm: h["text_norm"],
        bbox: h["bbox"] || {},
        confidence: h["confidence"],
        kind: h["kind"],
        revision: false,
        revision_comment: nil,
        created_at: now,
        modified_date: now,
        modified_by: nil
      }
    end

    return if rows.empty?

    if mode == "append"
      # honor unique constraint; will error on duplicates
      Sc06Ocr::OcrToken.insert_all(rows)
    else
      # replace mode: safe even if payload repeats token_no
      Sc06Ocr::OcrToken.upsert_all(rows, unique_by: "uq_ocr_token_result_token_no")
    end
  end

  def ingest_review!(page_result_id, now)
    return unless params.key?(:review)

    h = params.require(:review)
    review = ActionController::Parameters.new(h).permit(
      :review_status, :review_note, :approved_text, :reviewed_at,
      reviewed_by: {}
    ).to_h

    # if status is set and not pending, stamp reviewed_at if missing
    if review["review_status"].present? && review["review_status"] != "pending"
      review["reviewed_at"] ||= now
    end

    row = {
      fk_page_result_id: page_result_id,
      review_status: review["review_status"] || "pending",
      review_note: review["review_note"],
      approved_text: review["approved_text"],
      reviewed_at: review["reviewed_at"],
      reviewed_by: review["reviewed_by"] || {},
      revision: false,
      revision_comment: nil,
      created_at: now,
      modified_date: now,
      modified_by: nil
    }

    Sc06Ocr::OcrReview.upsert_all([ row ], unique_by: "uq_ocr_review_page_result")
  end

  def ingest_links!(page_result_id, now, mode)
    return unless params.key?(:links)

    links = params.require(:links)
    unless links.is_a?(Array)
      raise ActionController::ParameterMissing, "links must be an array"
    end

    Sc06Ocr::OcrLink.where(fk_page_result_id: page_result_id).delete_all if mode == "replace"

    rows = links.map do |l|
      h = ActionController::Parameters.new(l).permit(
        :fk_index_id, :fk_entry_id, :link_kind, :link_conf, :note
      ).to_h

      {
        fk_page_result_id: page_result_id,
        fk_index_id: h["fk_index_id"],
        fk_entry_id: h["fk_entry_id"],
        link_kind: h["link_kind"],
        link_conf: h["link_conf"],
        note: h["note"],
        revision: false,
        revision_comment: nil,
        created_at: now,
        modified_date: now,
        modified_by: nil
      }
    end

    return if rows.empty?

    Sc06Ocr::OcrLink.insert_all(rows)
  end

  def limit_param
    lim = params[:limit].to_i
    return 50 if lim <= 0
    [ lim, 200 ].min
  end
end
