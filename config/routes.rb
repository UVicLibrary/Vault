Rails.application.routes.draw do
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
      end
    end
  end

  # For contacting users directly from the user#show page
  post 'hyrax/contact_user' => 'hyrax/contact_user_form#create', as: :contact_user_form_index
  get 'hyrax/contact_user' => 'hyrax/contact_user_form#new'

  # Upload a collection thumbnail
  post "/dashboard/collections/:id/delete_uploaded_thumbnail", to: "hyrax/dashboard/collections#delete_uploaded_thumbnail", as: :delete_uploaded_thumbnail

  # For CSV file path checker
  get "/dashboard/file_path_checker/upload", to: "file_path_checker#upload", as: :upload_csv_checker
  post "/dashboard/file_path_checker/upload", to: "file_path_checker#upload", as: :check_csv_upload

  # For changing collection visibility
  post '/dashboard/collections/:id/coll_visibility', to: 'hyrax/dashboard/collections#change_coll_visibility', as: 'coll_visibility'

  get 'status', to: 'status#index'

  mount BrowseEverything::Engine => '/browse'
  resource :site, only: [:update] do
    resources :roles, only: [:index, :update]
    resource :labels, only: [:edit, :update]
  end

  root 'hyrax/homepage#index'

  devise_for :users, controllers: { invitations: 'hyku/invitations', registrations: 'hyku/registrations' }
  mount Qa::Engine => '/authorities'

  mount Blacklight::Engine => '/'
  mount Hyrax::Engine, at: '/'

  Hyrax::Engine.routes do
    resources :featured_collection_lists
    resources :featured_collections
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

  mount Peek::Railtie => '/peek'
  mount Riiif::Engine => '/images', as: 'riiif'
  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.ability.admin? } do
  	mount Sidekiq::Web => '/sidekiq'
	end
  mount PdfjsViewer::Rails::Engine => "/pdfjs", as: 'pdfjs'
end
