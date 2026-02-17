
Doorkeeper provides:
    Doorkeeper::Application → oauth_applications
    Doorkeeper::AccessToken → oauth_access_tokens
    Doorkeeper::AccessGrant → oauth_access_grants

rails console

Doorkeeper::Application.count
Doorkeeper::AccessToken.order(created_at: :desc).limit(5).pluck(:token, :revoked_at)


To map a token to your user:
    current_user = User.find(doorkeeper_token.resource_owner_id)
