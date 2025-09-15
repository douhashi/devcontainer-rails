Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resource :sample, only: [ :show ]

  # Independent tracks listing (not nested under contents)
  resources :tracks, only: [ :index ]

  resources :contents do
    member do
      post :generate_tracks
      post :generate_single_track
      post :generate_audio
    end
    resources :tracks do
      collection do
        post :generate_single
        post :generate_bulk
      end
    end
    resources :artworks, except: [ :index, :show, :edit, :new ] do
      member do
        post :generate_thumbnail
        post :regenerate_thumbnail
        get "download/:variation", to: "artworks#download", as: :download
      end
    end
    resource :video, only: [ :create, :destroy ]
    resource :audio, only: [ :destroy ]
    resources :music_generations, only: [ :destroy ]
    resource :youtube_metadata, except: [ :show, :new, :edit ]
    resource :artwork_metadata, except: [ :show, :new, :edit ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "contents#index"

  # lookbook
  if Rails.application.config.lookbook_enabled
    mount Lookbook::Engine, at: "/dev/lookbook"
  end
end
