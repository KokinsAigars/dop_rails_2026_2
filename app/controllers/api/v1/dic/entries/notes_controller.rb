# frozen_string_literal: true

class Api::V1::Dic::Entries::NotesController < Api::V1::BaseController
  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]
  before_action :load_row, only: [ :update ]

  ENTRY_MODEL = Sc03Dictionary::DicEntry
  NOTE_MODEL = Sc03Dictionary::DicNote

  def load_row
    @row = NOTE_MODEL.find(params[:id])
  end

  def show
    note = NOTE_MODEL.find_by!(
      id: params[:id],
      fk_entry_id: params[:entry_id],
      fk_index_id: entry.fk_index_id
    )
    render json: note
  end

  def index
    entry = ENTRY_MODEL.find(params[:entry_id])
    render json: entry.dic_notes.order(:note_no, :created_at)
  end

  def create
    entry = ENTRY_MODEL.find(params[:entry_id])

    note = entry.dic_notes.new(permitted_params)
    note.fk_index_id = entry.fk_index_id
    note.save!

    render json: note, status: :created
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
    params.require(:dic_note).permit(
      :note_no, :note_note,
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
