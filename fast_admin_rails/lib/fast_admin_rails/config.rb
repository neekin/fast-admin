module FastAdminRails
  class Config
    attr_accessor :mount_path, :layout, :route_prefix, :dashboard_enabled, :user_class_name,
                  :require_authentication, :login_path_name, :session_user_key, :skip_auth_controllers
    attr_accessor :authorization_adapter, :auto_authorize, :skip_authz_controllers, :policy_namespace

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

      # 授权（权限）配置
      # :none | :pundit | :cancancan
      @authorization_adapter = :none
      # 自动为 RESTful 动作执行授权（需能推断资源类），默认关闭
      @auto_authorize = false
      # 在这些控制器上跳过自动授权
      @skip_authz_controllers = [
        "Admin::SessionsController",
        "Admin::RegistrationsController",
        "Admin::PasswordsController"
      ]
      # 可选策略命名空间（供自定义策略解析器使用）
      @policy_namespace = nil
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end
end
