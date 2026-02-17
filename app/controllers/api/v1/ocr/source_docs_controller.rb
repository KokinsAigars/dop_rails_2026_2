# frozen_string_literal: true

class Api::V1::Ocr::SourceDocsController < Api::V1::BaseController
  MODEL = Sc06Ocr::OcrSourceDoc

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  def index
    scope = MODEL.order(created_at: :desc)
    scope = scope.where(source_kind: params[:source_kind]) if params[:source_kind].present?
    scope = scope.limit(limit_param)

    render json: scope
  end

  def show
    row = MODEL.find(params[:id])
    render json: row
  end

  def create
    row = MODEL.new(source_doc_params)
    row.save!

    render json: row, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  # GET /api/v1/ocr/source_docs/:id/pages
  def pages
    doc = MODEL.find(params[:id])
    render json: doc.ocr_pages.order(:page_no)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  # GET /api/v1/ocr/source_docs/lookup?sha256=...  OR  ?uri=...
  def lookup
    if params[:sha256].present?
      # accept hex sha and pack it; if you store raw bytes, this lookup is handy.
      # If you store sha as bytea, you may prefer looking up by uri instead.
      doc = MODEL.find_by!(source_sha256: [ params[:sha256] ].pack("H*"))
      return render json: doc
    end

    if params[:uri].present?
      doc = MODEL.find_by!(source_uri: params[:uri])
      return render json: doc
    end

    render json: { error: "bad_request", details: "provide sha256 or uri" }, status: :bad_request
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  # ... index/show/create/pages/lookup already ...

  # GET /api/v1/ocr/source_docs/:id/full
  #
  # Payload:
  # - source_doc
  # - pages (ordered)
  # - for each page: its page_results (newest first), but not tokens/links/review (too heavy)
  #
  def full
    doc = MODEL
            .includes(ocr_pages: :ocr_page_results)
            .find(params[:id])

    render json: doc, include: {
      ocr_pages: {
        include: {
          ocr_page_results: {}
        }
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def source_doc_params
    params.require(:ocr_source_doc).permit(
      :source_kind,
      :source_uri,
      :source_sha256, # if you pass raw bytes; if you pass hex, convert in controller/pipeline
      doc_meta: {}
    )
  end

  def limit_param
    lim = params[:limit].to_i
    return 50 if lim <= 0
    [ lim, 200 ].min
  end
end
