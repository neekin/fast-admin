module Admin
  # 不继承 Admin::BaseController，避免参与菜单与认证过滤
  class RegistrationsController < ::ApplicationController
    def new
      @user = FastAdminRails.user_class.new
    end

    def create
      @user = FastAdminRails.user_class.new(user_params)
      if @user.save
        session[:admin_user_id] = @user.id
        return_to = session.delete(:admin_return_to)
        if return_to.present?
          redirect_to return_to, notice: "注册并登录成功"
        else
          redirect_to admin_home_path, notice: "注册并登录成功"
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.expect(admin_user: [ :email, :nickname, :password ])
    end
  end
end
