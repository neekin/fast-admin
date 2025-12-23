require "rails/engine"

module FastAdmin
  class Engine < ::Rails::Engine
    isolate_namespace FastAdmin

    initializer "fast_admin.configure" do
      # Placeholder for future configuration hooks
    end
  end
end
