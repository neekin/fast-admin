class Admin::PostsController < Admin::BaseController
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
