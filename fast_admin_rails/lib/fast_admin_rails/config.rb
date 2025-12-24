module FastAdminRails
  class Config
    attr_accessor :mount_path, :layout, :route_prefix, :dashboard_enabled, :user_class_name,
                  :require_authentication, :login_path_name, :session_user_key, :skip_auth_controllers

    def initialize
      @mount_path = "/admin"
      @layout = "admin"
      @route_prefix = "admin"
      @dashboard_enabled = true
      # 默认宿主使用 `User` 模型；若不存在则回退到引擎内置模型 `FastAdminRails::User`
      @user_class_name = "User"
      # 认证过滤配置
      @require_authentication = false
      # 登录页路由 helper 名称（Symbol）；将尝试调用该 helper，失败时回退到 /admin/sessions/new
      @login_path_name = :new_admin_session_path
      # 会话中存储已登录用户的 key
      @session_user_key = :admin_user_id
      # 在这些控制器上跳过认证检查（可扩展或清空以完全保护）
      @skip_auth_controllers = [
        "Admin::SessionsController",
        "Admin::RegistrationsController",
        "Admin::PasswordsController"
      ]
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end
end
