# frozen_string_literal: true

# Global state for the current request.
# Provides access to the currently authenticated user, session, and OAuth context.
#
# @!attribute [rw] user
#   @return [User, nil] The currently authenticated user.
# @!attribute [rw] session
#   @return [Session, nil] The current session record.
# @!attribute [rw] oauth_token
#   @return [String, nil] The current OAuth access token.
# @!attribute [rw] oauth_application
#   @return [Object, nil] The current OAuth application.
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session, :oauth_token, :oauth_application

  # The user associated with the current session.
  #
  # @return [User, nil] The user if a session exists, otherwise nil.
  def user
    session&.user
  end
end
