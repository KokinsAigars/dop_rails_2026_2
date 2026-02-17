# frozen_string_literal: true

class Api::V1::Dic::EntriesController < Api::V1::BaseController
  before_action -> { doorkeeper_authorize! :admin }, except: %i[index show history]

  ENTRY_MODEL = Sc03Dictionary::DicEntry

  def show
    entry = ENTRY_MODEL
              .includes(:dic_refs, :dic_notes, :dic_quotes, :dic_egs)
              .find(params[:id])

    render json: entry, include: [ :dic_refs, :dic_notes, :dic_quotes, :dic_egs ]
  end

  def update
    set_db_audit_reason("dic_entry api update -> new version")

    row = ENTRY_MODEL.find(params[:id])

    new_row = row.create_new_version!(
      attrs: entry_params,
      modified_by: modified_by_for("api update -> new version")
    )

    render json: new_row, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_error", details: e.record.errors }, status: :unprocessable_entity
  end


  private

  def entry_params
    params.require(:dic_entry).permit(
      :lang, :dictionary, :entry_version, :entry_no, :letter,
      :name, :name_orig, :dic_name, :dic_name_orig, :dic_eng_tr,
      :gender, :grammar, :etymology, :compare, :compare_sanskrit,
      :sanskrit, :opposite, :vedic, :note, :xref,
      :revision, :revision_comment
    )
  end
end
