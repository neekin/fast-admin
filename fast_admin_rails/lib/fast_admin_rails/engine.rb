require "rails/engine"

module FastAdminRails
  class Engine < ::Rails::Engine
    isolate_namespace FastAdminRails
  end
end
