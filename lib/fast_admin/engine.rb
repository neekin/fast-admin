# Minimal Rails Engine skeleton for future gem extraction
require "rails"

module FastAdmin
  class Engine < ::Rails::Engine
    # Do not isolate namespace for now to avoid route/view changes in host app
    # isolate_namespace FastAdmin

    initializer "fast_admin.configure" do
      # Ensure FastAdmin config is initialized
      FastAdmin.config
    end

    # Eager load the FastAdmin namespace when Rails eager loads
    config.eager_load_namespaces << FastAdmin
  end
end
