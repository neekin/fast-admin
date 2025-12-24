require "rails/generators"
require "rails/generators/active_record"

module FastAdmin
  module Generators
    class UserGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :table_name, type: :string, default: "fast_admin_users", desc: "Table name for fallback user model"

      desc "Generates migration for FastAdminRails fallback user model (email, nickname, password_digest)."

      def create_migration_file
        migration_name = "create_#{options[:table_name]}"
        template "create_fast_admin_users.rb.tt", File.join("db/migrate", "#{timestamp}_#{migration_name}.rb")
      end

      private

      def timestamp
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
