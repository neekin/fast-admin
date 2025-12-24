module Admin
  # Gem 提供的 Admin 基类：直接继承宿主 ApplicationController，避免耦合
  class BaseController < ::ApplicationController
    layout -> { FastAdminRails.config.layout }
    # 使类具备 DSL（menu_item、list_item_actions、default_actions 等）
    class << self
      include FastAdmin::DSL
    end

    # 子类注册到 Registry，并确保 DSL 方法可用
    def self.inherited(subclass)
      super
      begin
        FastAdmin::Registry.register(subclass)
        subclass.extend(FastAdmin::DSL)
      rescue NameError
        # 初始化时未加载也可忽略
      end
    end

    helper_method :current_admin_user

    before_action :authenticate_admin!, if: -> { FastAdminRails.config.require_authentication }

    private

    def current_admin_user
      key = FastAdminRails.config.session_user_key
      uid = session[key]
      return @current_admin_user if defined?(@current_admin_user)
      return (@current_admin_user = nil) unless uid
      begin
        @current_admin_user = FastAdminRails.user_class.find_by(id: uid)
      rescue => _e
        @current_admin_user = nil
      end
    end

    def authenticate_admin!
      return if skip_auth_controller?
      return if current_admin_user
      # 记录原始目标用于登录后跳转
      session[:admin_return_to] = request.fullpath
      redirect_to resolve_login_path, alert: "请先登录"
    end

    def skip_auth_controller?
      FastAdminRails.config.skip_auth_controllers.include?(self.class.name)
    end

    def resolve_login_path
      helper = FastAdminRails.config.login_path_name
      if helper && respond_to?(helper)
        send(helper)
      elsif defined?(main_app) && helper && main_app.respond_to?(helper)
        main_app.send(helper)
      else
        # 回退：尝试 RESTful URL，再最终拼接路径
        begin
          url_for(controller: "admin/sessions", action: :new)
        rescue
          File.join(FastAdminRails.config.mount_path, "sessions/new")
        end
      end
    end
  end
end
