Rails.application.routes.draw do
  # Mount Engine and draw host admin resources under the same scoped path (with block flexibility)
  scope path: "/fa-admin", as: :admin, module: :admin do
    mount FastAdminRails::Engine => "/"
    # Auto-draw resources for Admin::* controllers under this scope
    FastAdmin::Routing.draw_admin(self, use_scope: true, as: :admin)
    # You can add extra routes here if needed
    # resources :reports
    get "home", to: "home#index"
    root to: "home#index"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
