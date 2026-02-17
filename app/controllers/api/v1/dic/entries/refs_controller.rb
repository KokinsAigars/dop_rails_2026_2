# frozen_string_literal: true

class Api::V1::Dic::Entries::RefsController < Api::V1::BaseController
  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]
  before_action :load_row, only: [ :update ]

  ENTRY_MODEL = Sc03Dictionary::DicEntry
  REF_MODEL = Sc03Dictionary::DicRef

  def load_row
    @row = REF_MODEL.find(params[:id])
  end

  def show
    entry = ENTRY_MODEL.select(:id, :fk_index_id).find(params[:entry_id])

    ref = REF_MODEL.find_by!(
      id: params[:id],
      fk_entry_id: params[:entry_id],
      fk_index_id: entry.fk_index_id
    )

    render json: ref
  end

  def index
    entry = ENTRY_MODEL.find(params[:entry_id])
    render json: entry.dic_refs.order(:ref_no, :created_at)
  end

  def create
    entry = ENTRY_MODEL.find(params[:entry_id])

    ref = entry.dic_refs.new(permitted_params)
    ref.fk_index_id = entry.fk_index_id
    ref.save!

    render json: ref, status: :created
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
    params.require(:dic_ref).permit(
      :ref_no, :ref_note, :ref_name, :ref_etymology, :ref_compare,
      :ref_compare_sanskrit, :ref_opposite, :ref_xref,
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
