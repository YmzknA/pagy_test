Rails.application.routes.draw do
  root "performance#index"
  
  get "performance/index"
  
  # 各ページネーション手法の独立したデモ
  get "performance/pagy_standard_demo"
  get "performance/pagy_countless_demo" 
  get "performance/kaminari_standard_demo"
  get "performance/kaminari_without_count_demo"
  
  # 既存のルート（互換性維持）
  get "performance/pagy_demo", to: "performance#pagy_standard_demo"
  get "performance/kaminari_demo", to: "performance#kaminari_standard_demo"
  
  
  # Simple verification pages
  get "verification/pagy_standard_simple"
  get "verification/pagy_countless_simple" 
  get "verification/kaminari_standard_simple"
  get "verification/kaminari_without_count_simple"
  
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
