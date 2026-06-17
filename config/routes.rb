Rails.application.routes.draw do
  mount_avo

  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  delete "sign_out", to: "sessions#sign_out"
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  resources :sessions, only: [:index, :show, :destroy]
  resource  :password, only: [:edit, :update]
  namespace :identity do
    resource :email,              only: [:edit, :update]
    resource :email_verification, only: [:show, :create]
    resource :password_reset,     only: [:new, :edit, :create, :update]
  end
  # root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"

  resource :locale, only: :update

  get "search", to: "search#index"

  post "notion/sync/:record_type/:slug", to: "notion_syncs#create", as: :notion_sync,
    constraints: { record_type: /projects|talks|reviews|media/ }

  resources :clients, only: %i[index]
  get "clients/:slug", to: "clients#show", as: :client
  get "clients/:client_slug/:project_slug", to: "projects#show", as: :client_project

  resources :media, only: %i[index show], param: :slug
  resources :talks, only: %i[index show], param: :slug
  resources :reviews, only: %i[index show], param: :slug
  resources :blog, only: %i[index show], param: :slug, controller: "blog_posts"

  resources :projects, only: %i[index show], param: :slug do
    collection do
      get ":kind/:tag",
          to: "projects#collection",
          as: :collection,
          constraints: { kind: /roles|deliverables|directions/ }
    end
  end
end
