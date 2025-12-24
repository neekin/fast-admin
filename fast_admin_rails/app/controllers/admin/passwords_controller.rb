module Admin
  # 不继承 Admin::BaseController，避免参与菜单与认证过滤
  class PasswordsController < ::ApplicationController
    def new
    end

    def create
      klass = FastAdminRails.user_class
      @user = klass.find_by(email: params.dig(:admin_password, :email))
      if @user
        token = SecureRandom.hex(16)
        if @user.respond_to?(:reset_password_token) && @user.respond_to?(:reset_password_sent_at)
          @user.update(reset_password_token: token, reset_password_sent_at: Time.current)
        end
        flash[:notice] = "重置链接已生成：?token=#{token}（示例）"
      else
        flash[:alert] = "邮箱不存在"
      end
      redirect_to new_admin_password_path
    end

    def edit
      @token = params[:token]
      klass = FastAdminRails.user_class
      @user = klass.find_by(reset_password_token: @token)
      unless @user
        redirect_to new_admin_password_path, alert: "链接无效或已过期"
      end
    end

    def update
      klass = FastAdminRails.user_class
      @user = klass.find_by(reset_password_token: params.dig(:admin_password, :token))
      if @user && @user.update(password: params.dig(:admin_password, :password), reset_password_token: nil)
        redirect_to new_admin_session_path, notice: "密码已重置，请登录"
      else
        flash.now[:alert] = "重置失败"
        @token = params.dig(:admin_password, :token)
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
