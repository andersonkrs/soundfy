Rails.application.routes.draw do
  root to: "shopify/home#index"

  mount ShopifyApp::Engine, at: "/"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  namespace :shopify do
    get "/home", to: "home#index"

    # resources :warranties, only: %i[index]

    namespace :webhooks do
      # Compliance webhooks
      post "app_uninstalled", to: "app_uninstalled#receive"
      post "customers_redact", to: "customers_redact#receive"
      post "customers_data_request", to: "customers_data_request#receive"

      # App webhooks
      post "products_create", to: "products_create#receive"
      post "products_update", to: "products_update#receive"
      post "products_delete", to: "products_delete#receive"

      post "collections_create", to: "collections_create#receive"
      post "collections_update", to: "collections_update#receive"
      post "collections_delete", to: "collections_delete#receive"
    end
  end

  namespace :admin do
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
