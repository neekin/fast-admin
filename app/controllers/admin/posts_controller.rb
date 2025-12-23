class Admin::PostsController < Admin::BaseController
  # 隐藏默认的“删除”按钮；查看/编辑仍显示
  default_actions delete: false
  # 覆盖默认“编辑”按钮的 HTML 示例
  default_actions_html edit: ->(post) {
    link_to("编辑", edit_admin_post_path(post), class: "px-2 py-1 rounded bg-green-600 text-white hover:bg-green-700")
  }
  # 搜索表单字段配置
  search_fields do
    search_field name: :title, type: :text, label: "标题", order: 1
    search_field name: :content, type: :text, label: "内容", order: 2
  end
  # 列表级别批量操作配置
  list_actions do
    list_action name: "批量审核", path: :bulk_approve_admin_posts_path, method: :patch, order: 1, css_class: "px-3 py-1 rounded bg-purple-600 text-white hover:bg-purple-700"
    list_action name: "批量删除", path: :bulk_destroy_admin_posts_path, method: :delete, confirm: "确定要删除所选吗？", order: 2, css_class: "px-3 py-1 rounded bg-red-600 text-white hover:bg-red-700"
  end
  menu_item name: "文章管理", icon: "article", order: 20, show_list_item: false,
    submenu: [
      { name: "审核", path: :pending_admin_posts_path, order: 1 }
    ]

  # 配置列表项的自定义操作按钮
  # 这里使用路由 helper 的 symbol，实际调用在 helper 中完成
  list_item_actions do
    action name: "审核",
           path: :approve_admin_post_path,
           method: :patch,
           order: 1,
           css_class: "text-purple-600 hover:text-purple-800"
  end

  before_action :set_admin_post, only: %i[ show edit update destroy approve ]
  # GET /admin/posts or /admin/posts.json
  def index
    @admin_posts = Admin::Post.all
    # 简单搜索：对配置的文本字段执行包含匹配（LIKE）
    if params[:q].present?
      controller_class = self.class
      controller_class.search_fields_config.each do |f|
        name = f[:name].to_s
        val = params[:q][name]
        next if val.blank?
        # 仅对 text/number 进行基本过滤；select 可根据具体字段自行扩展
        case f[:type].to_sym
        when :text
          @admin_posts = @admin_posts.where("#{name} LIKE ?", "%#{val}%")
        when :number
          @admin_posts = @admin_posts.where(name => val)
        when :select
          @admin_posts = @admin_posts.where(name => val)
        end
      end
    end
  end

  # 批量审核（如果存在 status 字段则更新，否则直接返回提示）
  def bulk_approve
    ids = Array(params[:ids]).compact
    if ids.empty?
      redirect_to admin_posts_path, alert: "请选择需要审核的记录" and return
    end
    if Admin::Post.column_names.include?("status")
      Admin::Post.where(id: ids).update_all(status: "approved")
      redirect_to admin_posts_path, notice: "已批量审核通过"
    else
      redirect_to admin_posts_path, alert: "当前模型未包含 status 字段，无法批量审核"
    end
  end

  # 批量删除
  def bulk_destroy
    ids = Array(params[:ids]).compact
    if ids.empty?
      redirect_to admin_posts_path, alert: "请选择需要删除的记录" and return
    end
    Admin::Post.where(id: ids).destroy_all
    redirect_to admin_posts_path, notice: "已批量删除"
  end

  # GET /admin/posts/1 or /admin/posts/1.json
  def show
  end
  def pending
    @admin_posts = Admin::Post.where(status: "pending")
  end

  # PATCH /admin/posts/:id/approve
  def approve
    @admin_post.update(status: "approved")
    respond_to do |format|
      format.html { redirect_to admin_posts_path, notice: "文章已审核通过" }
      format.json { render :show, status: :ok }
    end
  end
  # GET /admin/posts/new
  def new
    @admin_post = Admin::Post.new
  end

  # GET /admin/posts/1/edit
  def edit
  end

  # POST /admin/posts or /admin/posts.json
  def create
    @admin_post = Admin::Post.new(admin_post_params)

    respond_to do |format|
      if @admin_post.save
        format.html { redirect_to @admin_post, notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @admin_post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/posts/1 or /admin/posts/1.json
  def update
    respond_to do |format|
      if @admin_post.update(admin_post_params)
        format.html { redirect_to @admin_post, notice: "Post was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @admin_post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/posts/1 or /admin/posts/1.json
  def destroy
    @admin_post.destroy!

    respond_to do |format|
      format.html { redirect_to admin_posts_path, notice: "Post was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_post
      @admin_post = Admin::Post.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def admin_post_params
      params.expect(admin_post: [ :title, :content ])
    end
end
