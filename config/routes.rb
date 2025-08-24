Rails.application.routes.draw do
  root "performance#index"
  
  get "performance/index"
  get "performance/pagy_demo"
  get "performance/kaminari_demo"
  get "performance/pagy_optimized_demo"
  get "performance/kaminari_optimized_demo"
  get "performance/benchmark"
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by uptime monitors like Pingdom, StatusCake, etc.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
