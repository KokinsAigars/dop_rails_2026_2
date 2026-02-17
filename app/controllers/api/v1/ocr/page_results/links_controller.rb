# frozen_string_literal: true

class Api::V1::Ocr::PageResults::LinksController < Api::V1::BaseController
  LINK_MODEL = Sc06Ocr::OcrLink
  PAGE_RESULT_MODEL = Sc06Ocr::OcrPageResult

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]


  def index
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])
    links = page_result.ocr_links.order(:created_at)
    render json: links
  end

  def show
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])
    link = page_result.ocr_links.find(params[:id])
    render json: link
  end

  def create
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])
    link = page_result.ocr_links.new(link_params)
    link.save!
    render json: link, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found", details: "page_result not found" }, status: :not_found
  end

  def update
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])
    link = page_result.ocr_links.find(params[:id])
    link.update!(link_params)
    render json: link, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  def destroy
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])
    link = page_result.ocr_links.find(params[:id])
    link.destroy!
    render json: { deleted: true }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  # POST .../links/bulk_create
  # { "links": [ {link_kind:"candidate_entry", fk_entry_id:"...", link_conf: 88.2, note:"..."}, ...] }
  def bulk_create
    page_result_id = params[:page_result_id]
    PAGE_RESULT_MODEL.find(page_result_id) # ensure exists

    rows = bulk_links_params.map do |h|
      {
        fk_page_result_id: page_result_id,
        fk_index_id: h[:fk_index_id],
        fk_entry_id: h[:fk_entry_id],
        link_kind: h[:link_kind],
        link_conf: h[:link_conf],
        note: h[:note],

        revision: false,
        revision_comment: nil,

        created_at: Time.current,
        modified_date: Time.current,
        modified_by: nil
      }
    end

    return render json: { error: "no_links" }, status: :unprocessable_entity if rows.empty?

    # Fast ingestion path; relies on DB constraints.
    LINK_MODEL.insert_all(rows)

    render json: { inserted: rows.size }, status: :created
  rescue ActionController::ParameterMissing => e
    render json: { error: "bad_request", details: e.message }, status: :bad_request
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found", details: "page_result not found" }, status: :not_found
  end

  private

  def link_params
    params.require(:ocr_link).permit(
      :fk_index_id,
      :fk_entry_id,
      :link_kind,
      :link_conf,
      :note
    )
  end

  def bulk_links_params
    params.require(:links).map do |l|
      ActionController::Parameters.new(l).permit(
        :fk_index_id,
        :fk_entry_id,
        :link_kind,
        :link_conf,
        :note
      ).to_h.symbolize_keys
    end
  end
end
