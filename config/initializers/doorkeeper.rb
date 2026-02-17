# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  # only for python scripts, not browser clients
  api_only

  default_scopes :public
  optional_scopes :admin

  grant_flows %w[client_credentials authorization_code]

  enforce_configured_scopes

  # hash_application_secrets

  allow_blank_redirect_uri true

  access_token_expires_in 2.hours
end
