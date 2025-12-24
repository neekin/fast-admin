# frozen_string_literal: true

require "rails"

require_relative "fast_admin/config"
require_relative "fast_admin/dsl"
require_relative "fast_admin/registry"
require_relative "fast_admin_rails/config"
require_relative "fast_admin_rails/engine"
require_relative "fast_admin_rails/user"
require_relative "fast_admin_rails/authorization"
require_relative "fast_admin_rails/rbac"
require_relative "fast_admin_rails/rbac/role"
require_relative "fast_admin_rails/rbac/permission"
require_relative "fast_admin_rails/rbac/role_permission"
require_relative "fast_admin_rails/rbac/user_role"
require_relative "fast_admin_rails/policies/application_policy"
require_relative "fast_admin_rails/policy_factory"

module FastAdminRails
  # Configure FastAdminRails only (mount path etc.)
  def self.configure
    yield(FastAdminRails.config)
  end

  # 返回用户模型类：优先宿主配置的类名（默认 "User"），不存在则回退到引擎内置 `FastAdminRails::User`
  def self.user_class
    name = FastAdminRails.config.user_class_name
    klass = name.is_a?(String) ? name.safe_constantize : nil
    return klass if klass

    fallback = "FastAdminRails::User".safe_constantize
    return fallback if fallback

    raise NameError, "FastAdminRails user class not found: #{name} nor FastAdminRails::User"
  end
end
