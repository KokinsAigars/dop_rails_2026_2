# frozen_string_literal: true

# Join model that links a {User} to a {Role}.
#
# Ensures a user cannot have the same role assigned more than once.
#
# @!attribute [rw] user
#   @return [User] The associated user.
# @!attribute [rw] role
#   @return [Role] The associated role.
# @!attribute [r] user_id
#   @return [String] Foreign key referencing the user.
# @!attribute [r] role_id
#   @return [String] Foreign key referencing the role.
class UserRole < ApplicationRecord
  belongs_to :user, inverse_of: :user_roles
  belongs_to :role, inverse_of: :user_roles

  # Uniqueness constraint for the composite pair (user_id, role_id)
  validates :user_id, uniqueness: { scope: :role_id }
end
