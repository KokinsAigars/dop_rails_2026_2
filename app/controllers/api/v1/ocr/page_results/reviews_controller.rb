# frozen_string_literal: true

class Api::V1::Ocr::PageResults::ReviewsController < Api::V1::BaseController
  REVIEW_MODEL = Sc06Ocr::OcrReview
  PAGE_RESULT_MODEL = Sc06Ocr::OcrPageResult

  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]


  def show
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])
    review = page_result.ocr_review

    return render json: { error: "not_found" }, status: :not_found if review.nil?

    render json: review
  end

  def create
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])

    # if already exists, either fail or treat as upsert. I prefer fail-fast.
    if page_result.ocr_review.present?
      return render json: { error: "already_exists" }, status: :conflict
    end

    review = REVIEW_MODEL.new(review_params.merge(fk_page_result_id: page_result.id))
    review.save!

    render json: review, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found", details: "page_result not found" }, status: :not_found
  end

  def update
    page_result = PAGE_RESULT_MODEL.find(params[:page_result_id])
    review = page_result.ocr_review

    return render json: { error: "not_found" }, status: :not_found if review.nil?

    # Optional: if status moves away from pending, stamp reviewed_at unless provided
    attrs = review_params.to_h
    if attrs.key?("review_status") && attrs["review_status"] != "pending"
      attrs["reviewed_at"] ||= Time.current
    end

    review.update!(attrs)

    render json: review, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found", details: "page_result not found" }, status: :not_found
  end

  private

  def review_params
    params.require(:ocr_review).permit(
      :review_status,
      :review_note,
      :approved_text,
      :reviewed_at,
      reviewed_by: {}
    )
  end
end
