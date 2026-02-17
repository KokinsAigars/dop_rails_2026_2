# frozen_string_literal: true

class Api::V1::Ocr::RunsController < Api::V1::BaseController
  MODEL = Sc06Ocr::OcrRun

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.limit(limit_param)

    render json: scope
  end

  def show
    run = MODEL.find(params[:id])
    render json: run
  end

  def create
    run = MODEL.new(run_params)
    run.save!

    render json: run, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # High-value endpoint for dashboards & pipeline checks
  def summary
    run = MODEL
            .includes(:ocr_page_results)
            .find(params[:id])

    render json: {
      run: run,
      stats: {
        pages_total: run.ocr_page_results.count,
        pages_with_tokens: run.ocr_page_results.joins(:ocr_tokens).distinct.count,
        pages_reviewed: run.ocr_page_results.joins(:ocr_review).count,
        pages_linked: run.ocr_page_results.joins(:ocr_links).distinct.count
      }
    }
  end

  # ... index/show/create/summary already ...

  # GET /api/v1/ocr/runs/:id/full
  #
  # Payload:
  # - run
  # - page_results
  # - for each page_result: page (so you know page_no + doc)
  # - optionally review + links summary (not tokens)
  #
  def full
    run = MODEL
            .includes(ocr_page_results: [ :page, :ocr_review, :ocr_links ])
            .find(params[:id])

    render json: run, include: {
      ocr_page_results: {
        include: {
          page: {},
          ocr_review: {},
          ocr_links: {}
        }
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end


  private

  def run_params
    params.require(:ocr_run).permit(
      :engine,
      :engine_version,
      :status,
      :log,
      :started_at,
      :finished_at,
      lang_hint: [],
      config: {}
    )
  end

  def limit_param
    lim = params[:limit].to_i
    return 50 if lim <= 0
    [ lim, 200 ].min
  end
end
