class Admin::UsersController < Admin::BaseController
  menu_item name: "用户管理", icon: "users", order: 10

  search_fields do
    search_field name: :email, type: :text, label: "邮箱", order: 1
    search_field name: :nickname, type: :text, label: "昵称", order: 2
  end

  list_item_fields do
    list_item_field name: :id, label: "ID", order: 0
    list_item_field name: :email, label: "邮箱", order: 1
    list_item_field name: :nickname, label: "昵称", order: 2
  end

  def index
    klass = FastAdminRails.user_class
    scope = klass.all
    q = params[:q] || {}
    if q[:email].present?
      scope = scope.where("email LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(q[:email])}%")
    end
    if q[:nickname].present?
      scope = scope.where("nickname LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(q[:nickname])}%")
    end
    @admin_users = scope.order(id: :desc).limit(100)
  end

  def show
    @user = FastAdminRails.user_class.find(params[:id])
  end

  def new
    @user = FastAdminRails.user_class.new
  end

  def edit
    @user = FastAdminRails.user_class.find(params[:id])
  end

  def create
    @user = FastAdminRails.user_class.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @user = FastAdminRails.user_class.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "更新成功"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user = FastAdminRails.user_class.find(params[:id])
    @user.destroy
    redirect_to admin_users_path, notice: "已删除"
  end

  private

  def user_params
    # Rails 8+ strong params
    params.expect(admin_user: [ :email, :nickname, :password ])
  end
end
