require "rails/generators"

module FastAdmin
  module Rbac
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs RBAC tables (roles, permissions, role_permissions, user_roles) for fast_admin_rails"

      def create_migrations
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        template "create_fa_roles.rb.tt", File.join("db/migrate", "#{timestamp}_create_fa_roles.rb")
        template "create_fa_permissions.rb.tt", File.join("db/migrate", "#{next_ts(timestamp)}_create_fa_permissions.rb")
        template "create_fa_role_permissions.rb.tt", File.join("db/migrate", "#{next_ts(next_ts(timestamp))}_create_fa_role_permissions.rb")
        template "create_fa_user_roles.rb.tt", File.join("db/migrate", "#{next_ts(next_ts(next_ts(timestamp)))}_create_fa_user_roles.rb")
      end

      private

      def next_ts(ts)
        (Time.strptime(ts, "%Y%m%d%H%M%S") + 1).utc.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
