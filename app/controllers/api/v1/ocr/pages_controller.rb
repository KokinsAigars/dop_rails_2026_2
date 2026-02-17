# frozen_string_literal: true

class Api::V1::Ocr::PagesController < Api::V1::BaseController
  MODEL = Sc06Ocr::OcrPage

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.order(:fk_source_doc_id, :page_no)
    scope = scope.where(fk_source_doc_id: params[:source_doc_id]) if params[:source_doc_id].present?
    scope = scope.limit(limit_param)

    render json: scope
  end

  def show
    row = MODEL.find(params[:id])
    render json: row
  end

  # GET /api/v1/ocr/pages/:id/results
  def results
    page = MODEL.find(params[:id])

    results = page.ocr_page_results
                  .order(created_at: :desc)

    render json: results
  end

  # GET /api/v1/ocr/pages/lookup?source_doc_id=...&page_no=...
  def lookup
    row = MODEL.find_by!(
      fk_source_doc_id: params.require(:source_doc_id),
      page_no: params.require(:page_no).to_i
    )

    render json: row
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  # ... index/show/results/lookup already ...

  # GET /api/v1/ocr/pages/:id/full
  #
  # Payload:
  # - page
  # - page_results (newest first)
  # - each page_result includes review + links (but NOT tokens)
  #
  def full
    page = MODEL
             .includes(ocr_page_results: [ :ocr_review, :ocr_links ])
             .find(params[:id])

    render json: page, include: {
      ocr_page_results: {
        include: {
          ocr_review: {},
          ocr_links: {}
        }
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  # GET /api/v1/ocr/pages/:id/latest_full
  #
  # Deep payload for newest page_result only:
  # - page_result + tokens + review + links
  #
  def latest_full
    page = MODEL.find(params[:id])

    latest = page.ocr_page_results.order(created_at: :desc).limit(1).first
    return render json: { error: "not_found", details: "no page_results" }, status: :not_found if latest.nil?

    row = Sc06Ocr::OcrPageResult
            .includes(:ocr_tokens, :ocr_review, :ocr_links)
            .find(latest.id)

    render json: row, include: { ocr_tokens: {}, ocr_review: {}, ocr_links: {} }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def limit_param
    lim = params[:limit].to_i
    return 50 if lim <= 0
    [ lim, 200 ].min
  end
end
