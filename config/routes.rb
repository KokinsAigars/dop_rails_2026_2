# bin/rails routes
# bin/rails routes -g search_indexes

# frozen_string_literal: true

Rails.application.routes.draw do
  use_doorkeeper
  # resource :session
  resources :passwords, only: [ :new, :create, :edit, :update ], param: :token

  get "/up" => "rails/health#show", as: :rails_health_check

  get "robots", to: "home#robots"

  # localized do
  scope "(:locale)", locale: /en|lv/ do
    root "home#index"
    get "/", to: "home#index"

    post "/set_locale", to: "locales#update", as: :set_locale

    get "search", to: "search#index", as: :search


    get "/signup", to: "registrations#new", as: :signup
    resources :registrations, only: [ :new, :create ] do
      collection do
        get :sent # This creates /registrations/sent
      end
    end
    get "registration/verify", to: "registrations#verify", as: :registration_verify
    post "registrations/check_email", to: "registrations#check_email"
    get "registration_verification_sent", to: "registrations#verification_sent", as: :verification_sent
    resources :sessions, only: [ :index, :new, :create, :update, :destroy ] do
      post :verify_email, on: :collection # step 1: username/email exists?
      post :verify_password, on: :collection # step 2: check password (no session yet)
    end
    get "/login",  to: "sessions#new",     as: :login
    match "/logout", to: "sessions#destroy", as: :logout, via: [ :get, :delete ]
    resources :passwords, param: :token, only: [ :new, :create, :edit, :update ] do
      collection do
        get :sent # This creates /passwords/sent
      end
    end

    get "terms", to: "terms#index"
    get "cookie_consent", to: "cookie_consent#index"



    # --- Account/User Universe ---
    namespace :account do
      root to: "management/workspace#index"

      namespace :management do

        resource :settings, only: [] do
          patch :update_ui, on: :collection
        end
      end
    end

    # --- Admin Universe ---
    namespace :admin do
      # Points to /admin
      root to: "management/workspace#index"

      namespace :management do
        # Workspace home
        get 'workspace', to: 'workspace#index', as: :workspace

        resources :users

        # Ensure this matches your controller: Admin::Management::OauthApplicationsController
        resources :oauth_applications do
          member do
            post :rotate_secret
            post :revoke_tokens
          end
        end

        resources :bot_attempts, only: [:index, :show]
        resources :global_configs, only: [:index, :update]
      end
    end

    # --- Dictionary ---
    scope module: 'dictionary' do

      namespace :abbr do
        resources :books_periodicals, only: [:index, :show]
        resources :general_terms, only: [:index, :show]
        resources :grammatical_terms, only: [:index, :show]
        resources :publication_sources, only: [:index, :show] do
          get :history, on: :member
        end
        resources :typographicals, only: [:index, :show] do
          get :history, on: :member
        end
      end

      namespace :ref do
        resources :bibliographies, only: [:index, :show]
        resources :internet_sources, only: [:index, :show]
        resources :texts, only: [:index, :show]
      end

      namespace :dic do
        # This makes http://localhost:3000/dic the search entry point
        # Point the root to your new SearchIndex controller
        root to: 'search_indexes#index'

        resources :search_indexes, only: [:index]
        resources :entries, only: [:index, :show]
      end

    end


  end

  namespace :api, defaults: { format: "json" } do
    namespace :v1 do
      get "/ping", to: "ping#show"

      namespace :abbr do
        %i[
          abbr_books_periodicals
          abbr_general_terms
          abbr_grammatical_terms
          abbr_publication_sources
          abbr_typographicals
          abbr_docs
        ].each do |res|
          resources res, only: %i[index show create update] do
            member { get :history }
          end
        end
      end

      namespace :ref do
        resources :ref_bibliographies, path: "ref_bibliography", only: [ :index, :show, :create, :update ]
        resources :ref_internet_sources, path: "ref_internet_sources", only: [ :index, :show, :create, :update ] do
          member do
            get :history
          end
        end
        resources :ref_texts, only: [ :index, :show, :create, :update ] do
          member do
            get :history
          end
        end
        resources :ref_docs, only: %i[index show create update] do
          member { get :history }
        end
      end

      namespace :dic do
        resources :indexes, only: [ :show, :create ] do
          resources :scans, only: [ :index, :show, :create ], module: :indexes
        end
        resources :entries, only: [ :show, :update ] do
          resources :refs,   only: [ :index, :show, :create, :destroy ], module: :entries
          resources :notes,  only: [ :index, :show, :create, :destroy ], module: :entries
          resources :quotes, only: [ :index, :show, :create, :destroy ], module: :entries
          resources :egs,    only: [ :index, :show, :create, :destroy ], module: :entries
        end

        # bin/rails routes -g indexes
        # /api/v1/dic/indexes/:id
        # /api/v1/dic/indexes/:index_id/scans
        # # /api/v1/dic/indexes/:index_id/scans/:id
        # /api/v1/dic/entries/:id
        # /api/v1/dic/entries/:entry_id/notes
        # /api/v1/dic/entries/:entry_id/notes/:id
        # bin/rails routes | grep "entries.*refs"
      end

      namespace :lang do
        resources :languages, only: %i[index show create update]
        resources :docs, only: %i[index show create update]
      end

      namespace :audit do
        resources :abbr_events, only: [ :index, :show ]
        resources :ref_events, only: [ :index, :show ]
        resources :dic_entry_events, only: [ :index, :show ]
      end

      namespace :ocr do
        get "source_docs/lookup", to: "source_docs#lookup"
        get "page_results/lookup", to: "page_results#lookup"

        resources :source_docs, only: [ :index, :show, :create ] do
          member do
            get :pages
            get :full
          end
        end

        resources :runs, only: [ :index, :show, :create ] do
          member do
            get :summary
            get :full
          end
        end

        resources :pages, only: [ :index, :show ] do
          # member → acts on one row
          member do
            get :results
            get :full
            get :latest_full
          end

          # collection → acts on the whole table
          collection do
            get :lookup
          end
        end

        resources :page_results, only: [ :index, :show ] do
          member do
            get :full
            post :ingest
          end

          scope module: :page_results do
            resources :tokens, only: [ :index, :show, :create ] do
              collection { post :bulk_create }
            end

            resource :review, only: [ :show, :create, :update ]

            resources :links, only: [ :index, :show, :create, :update, :destroy ] do
              collection { post :bulk_create }
            end
          end
        end
      end

      namespace :hash do
        get "temporary_hash/lookup", to: "temporary_hash#lookup"
        get "executed_sql_scripts/lookup", to: "executed_sql_scripts#lookup"

        resources :temporary_hash, only: [ :index, :create ] do
          collection do
            post :bulk_upsert
            delete :truncate
          end
        end

        resources :executed_sql_scripts, only: [ :index, :create ]
      end
    end
  end
end
