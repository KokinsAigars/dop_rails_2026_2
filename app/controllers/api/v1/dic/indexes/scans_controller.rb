# frozen_string_literal: true

class Api::V1::Dic::Indexes::ScansController < Api::V1::BaseController
  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  INDEX_MODEL = Sc03Dictionary::DicIndex
  SCAN_MODULE = Sc03Dictionary::DicScan

  def show
    scan = SCAN_MODULE.find_by!(
      id: params[:id],
      fk_index_id: params[:index_id])
    render json: scan
  end

  def index
    idx = INDEX_MODEL.find(params[:index_id])
    render json: idx.dic_scans.order(:scan_version, :created_at)
  end

  def create
    idx = INDEX_MODEL.find(params[:index_id])

    scan = idx.dic_scans.new(scan_params)
    scan.save!

    render json: scan, status: :created
  end

  private

  def scan_params
    params.require(:dic_scan).permit(
      :scan_version, :scan_filename, :scan_note, :scan_text, :scan_text_raw,
      :scan_status, :scan_meta, :revision, :revision_comment
    )
  end
end
