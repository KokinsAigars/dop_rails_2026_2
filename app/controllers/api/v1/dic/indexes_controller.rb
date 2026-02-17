# frozen_string_literal: true

class Api::V1::Dic::IndexesController < Api::V1::BaseController
  # before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  INDEX_MODEL = Sc03Dictionary::DicIndex

  def show
    idx = INDEX_MODEL
            .includes(dic_entries: [ :dic_refs, :dic_notes, :dic_quotes, :dic_egs ], dic_scans: [])
            .find(params[:id])

    render json: idx, include: {
      dic_entries: {
          include: [ :dic_refs, :dic_notes, :dic_quotes, :dic_egs ]
        },
        dic_scans: {}
      }
  end

  def create
    idx = INDEX_MODEL.create!(index_params)
    render json: idx, status: :created
  end

  private

  def index_params
    params.require(:dic_index).permit(
      :dictionary, :entry_no, :homograph, :homograph_no, :homograph_uuid,
      :source_file, :source_order, :xml_index_id,
      :revision, :revision_comment
    )
  end
end
