# frozen_string_literal: true

# Represents a user role within the system.
#
# @!attribute [rw] name
#   @return [String] The unique name of the role, stored in lowercase.
class Role < ApplicationRecord
  include GhostTraceable

  has_many :user_roles, inverse_of: :role, dependent: :destroy
  has_many :users, through: :user_roles

  before_validation :normalize_name

  validates :name, presence: true, uniqueness: true

  private

  # Normalizes the role name by converting it to a lowercase, stripped string.
  # Sets the name to nil if the resulting string is empty.
  #
  # @return [String, nil] The normalized name or nil.
  def normalize_name
    # Trace the "Before" and "After"
    private_ghost_trace("Normalizing Role Name: '#{name}'")

    self.name = name.to_s.strip.downcase.presence

    private_ghost_trace("Result: '#{self.name}'", trace: false)
  end
end
