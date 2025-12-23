FastAdminRails::Engine.routes.draw do
  if FastAdminRails.respond_to?(:config) ? FastAdminRails.config.dashboard_enabled : true
    root to: "dashboard#index"
    get "/dashboard", to: "dashboard#index"
  end
end
