# frozen_string_literal: true

class Api::V1::Dic::Entries::EgsController < Api::V1::BaseController
  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]
  before_action :load_row, only: [ :update ]

  ENTRY_MODEL = Sc03Dictionary::DicEntry
  EG_MODEL = Sc03Dictionary::DicEg

  def load_row
    @row = EG_MODEL.find(params[:id])
  end

  def show
    eg = EG_MODEL.find_by!(
      id: params[:id],
      fk_entry_id: params[:entry_id],
      fk_index_id: entry.fk_index_id
    )
    render json: eg
  end

  def index
    entry = ENTRY_MODEL.find(params[:entry_id])
    render json: entry.dic_egs.order(:eg_no, :created_at)
  end

  def create
    entry = ENTRY_MODEL.find(params[:entry_id])

    eg = entry.dic_egs.new(permitted_params)
    eg.fk_index_id = entry.fk_index_id
    eg.save!

    render json: eg, status: :created
  end

  def update
    set_db_audit_reason("dic_entry api update -> new version")

    new_row = @row.create_new_version!(
      attrs: permitted_params,
      modified_by: modified_by_for("api update -> new version")
    )

    render json: new_row, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end

  private

  def permitted_params
    params.require(:dic_eg).permit(
      :eg_no, :eg_note, :eg_name, :eg_etymology, :eg_compare,
      :eg_compare_sanskrit, :eg_opposite, :eg_xref,
      :bibliography_uuid,
      :citation_ref_src, :citation_abbrev, :citation_vol, :citation_part,
      :citation_p, :citation_pp, :citation_para,
      :citation_line, :citation_verse, :citation_char,
      :revision, :revision_comment
    )
  end

  def modified_by_for(reason)
    {
      actor: {
        type: "user",
        user_id: Current.user.id,
        email: Current.user.email_address
      },
      source: { app: "rails-ui" },
      change: { reason: reason }
    }
  end
end
