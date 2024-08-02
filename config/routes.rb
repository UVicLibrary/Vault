Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  concern :oai_provider, BlacklightOaiProvider::Routes.new
  #mount CdmMigrator::Engine => '/cdm_migrator'

  if Settings.multitenancy.enabled
    constraints host: Account.admin_host do
      get '/account/sign_up' => 'account_sign_up#new', as: 'new_sign_up'
      post '/account/sign_up' => 'account_sign_up#create'
      get '/', to: 'splash#index'

      # pending https://github.com/projecthydra-labs/hyrax/issues/376
      get '/dashboard', to: redirect('/')

      namespace :proprietor do
        resources :accounts
        resources :users
      end
    end
  end

  get '/load_more', to: 'hyrax/homepage#load_more', as: :load_more
  get '/google_map_behavior/getsolr', as: :getsolr

  get '/browse_collections/autocomplete', to: 'browse_collections#autocomplete'

  # For (dis)allowing downloads for an entire collection
  post '/dashboard/collections/:id/toggle_downloads', to: 'hyrax/dashboard/collections#toggle_downloads', as: 'toggle_downloads'

  # For copying collection permissions to its member works
  get '/dashboard/collections/:id/confirm_access', to: 'hyrax/dashboard/collections#confirm_access', as: 'confirm_collection_access_permission'
  post '/dashboard/collections/:id/copy_permissions', to: 'hyrax/dashboard/collections#copy_permissions', as: 'copy_collection_permissions'

  # For contacting users directly from the user#show page
  post 'hyrax/contact_user' => 'hyrax/contact_user_form#create', as: :contact_user_form_index
  get 'hyrax/contact_user' => 'hyrax/contact_user_form#new'

  # Upload a collection thumbnail
  post "/dashboard/collections/:id/delete_uploaded_thumbnail", to: "hyrax/dashboard/collections#delete_uploaded_thumbnail", as: :delete_uploaded_thumbnail

  # For CSV file path checker
  get "/dashboard/file_path_checker/upload", to: "file_path_checker#upload", as: :upload_csv_checker
  post "/dashboard/file_path_checker/upload", to: "file_path_checker#upload", as: :check_csv_upload

  # For changing collection visibility
  post '/dashboard/collections/:id/inherit_visibility', to: 'hyrax/dashboard/collections#inherit_visibility', as: 'inherit_collection_visibility'

  get '/fast_update/replace_uri', to: 'fast_update/changes#index', as: :fast_update_replace_uri
  get '/fast_update/search_preview', to: 'fast_update/changes#search_preview', as: :fast_update_search_preview
  get '/fast_update/search_preview/page/:page', to: 'fast_update/changes#search_preview'

  namespace :fast_update do
    resources :changes, except: [:update, :edit]
  end

  get 'status', to: 'status#index'

  mount BrowseEverything::Engine => '/browse'
  resource :site, only: [:update] do
    resources :roles, only: [:index, :update]
    resource :labels, only: [:edit, :update]
  end

  root 'hyrax/homepage#index'

  devise_for :users, controllers: { invitations: 'hyku/invitations', registrations: 'hyku/registrations', omniauth_callbacks: 'omniauth_sessions#create' }
  mount Qa::Engine => '/authorities'

  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'

  get '/advanced/facet', to: 'advanced#facet', as: 'advanced_facet_catalog'

  mount Hyrax::Engine, at: '/'
  mount Hyrax::DOI::Engine, at: '/doi', as: 'hyrax_doi'
  #mount ToSpotlight::Engine, at: '/to_spotlight'

  Hyrax::Engine.routes do
    resources :featured_collection_lists
    resource :featured_collection, only: [:create, :destroy]
  end

  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  curation_concerns_basic_routes do
    member do
      get :manifest
    end
  end

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable
    concerns :oai_provider
  end

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  namespace :admin do
    resource :account, only: [:edit, :update]
    resource :work_types, only: [:edit, :update]
    resources :users, only: [:destroy]
    resources :groups do
      member do
        get :remove
      end

      resources :users, only: [:index], controller: 'group_users' do
        collection do
          post :add
          delete :remove
        end
      end
    end
  end

  mount Riiif::Engine => '/images', as: 'riiif'
  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.ability.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  mount PdfjsViewer::Rails::Engine => "/pdfjs", as: 'pdfjs'
end
