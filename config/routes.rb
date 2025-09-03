Rails.application.routes.draw do
  get 'schedules/show'
  get 'profiles/show'
  get 'profiles/update'
  get 'pages/dashboard'
  devise_for :users
  root to: "pages#home"
  get "/dashboard", to: "pages#dashboard"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  resources :scans, only: [ :new, :create, :show ] do
    resources :recipes, only: [ :new, :create, :show ]
  end

  resources :recipes do
  collection do
    get :filters
  end
end

  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  resources :recipes, only: [:index]
  resources :recipes do
    resources :reviews, only: [:create, :index]
    post :toggle_favorite, on: :member
    post :like, on: :member
  end
  resource :profile, only: [:show, :update]
  resources :schedules, only: [:index, :create]
  # Defines the root path route ("/")
  # root "posts#index"
end
