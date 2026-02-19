
bin/rails generate doorkeeper:migration
bin/rails db:migrate


---
config/initializers/doorkeeper.rb
    
    Doorkeeper.configure do
        orm :active_record
        
        api_only
        
        default_scopes :admin
        optional_scopes :public
        
        grant_flows %w[client_credentials authorization_code password]
        
        # reject unknown scopes
        enforce_configured_scopes
        
        # hash_application_secrets
        
        access_token_expires_in 2.hours
    end
