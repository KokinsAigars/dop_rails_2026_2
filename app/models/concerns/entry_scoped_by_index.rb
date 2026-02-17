# frozen_string_literal: true

# Shared logic for models scoped by both an index and a dictionary entry.
# Ensures that the associated index matches the index of the associated dictionary entry.
#
# @!attribute [r] fk_index_id
#   @return [Integer] Unique ID of the associated {Sc03Dictionary::DicIndex}.
# @!attribute [r] fk_entry_id
#   @return [Integer] Unique ID of the associated {Sc03Dictionary::DicEntry}.
module EntryScopedByIndex
  extend ActiveSupport::Concern

  included do
    validates :fk_index_id, :fk_entry_id, presence: true
    validate :index_matches_entry
  end

  private

  # Validates that the associated index matches the index of the dictionary entry.
  # Adds an error to :fk_index_id if they do not match.
  #
  # @return [void]
  def index_matches_entry
    # We check if the including model responds to the association
    return unless respond_to?(:dic_entry) && dic_entry.present?

    if fk_index_id != dic_entry.fk_index_id
      errors.add(:fk_index_id, "must match dic_entry.fk_index_id")
    end
  end
end
