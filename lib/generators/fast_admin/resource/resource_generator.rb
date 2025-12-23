require "rails/generators/named_base"

module FastAdmin
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate admin index view with search, bulk actions, and item actions"

      def create_index_view
        plural = file_name.pluralize
        template "index.html.erb.tt", File.join("app/views/admin", plural, "index.html.erb")
      end
    end
  end
end
