require "rails/generators"

module FastAdmin
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install FastAdmin initializer and wiring"

      def copy_initializer
        template "fast_admin.rb.tt", "config/initializers/fast_admin.rb"
      end
    end
  end
end
