module Admin
  # 不继承 Admin::BaseController，避免参与菜单与认证过滤
  class SessionsController < ::ApplicationController
    def new
      @user = FastAdminRails.user_class.new
    end

    def create
      klass = FastAdminRails.user_class
      user = klass.find_by(email: params.dig(:admin_session, :email))
      if user && user.authenticate(params.dig(:admin_session, :password))
        session[:admin_user_id] = user.id
        return_to = session.delete(:admin_return_to)
        if return_to.present?
          redirect_to return_to, notice: "登录成功"
        else
          redirect_to admin_home_path, notice: "登录成功"
        end
      else
        flash.now[:alert] = "邮箱或密码错误"
        @user = klass.new(email: params.dig(:admin_session, :email))
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_user_id)
      redirect_to admin_home_path, notice: "已退出登录"
    end
  end
end
