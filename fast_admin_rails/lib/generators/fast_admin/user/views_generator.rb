require "rails/generators"

module FastAdmin
  module User
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Generates login, registration, and password reset views for admin"

      def create_views
        template "sessions_new.html.erb.tt", File.join("app/views/admin/sessions", "new.html.erb")
        template "registrations_new.html.erb.tt", File.join("app/views/admin/registrations", "new.html.erb")
        template "passwords_new.html.erb.tt", File.join("app/views/admin/passwords", "new.html.erb")
        template "passwords_edit.html.erb.tt", File.join("app/views/admin/passwords", "edit.html.erb")
        template "_auth_links.html.erb.tt", File.join("app/views/admin/shared", "_auth_links.html.erb")
      end
    end
  end
end
