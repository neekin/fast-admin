# fast_admin_rails

FastAdmin Rails 引擎与 DSL：为 Rails Admin 提供菜单、列表项动作、批量操作、搜索表单与生成器。

## 安装

在应用的 Gemfile 中添加（已在此仓库中使用本地路径示例）：

```ruby
gem "fast_admin_rails", path: "fast_admin_rails"
```

然后安装依赖：

```bash
bundle install
```

挂载 Engine（在宿主应用 routes.rb）：

```ruby
# config/routes.rb
mount FastAdminRails::Engine => FastAdminRails.config.mount_path
```

## 使用

- 在 `Admin::BaseController` 中：
  - `extend FastAdmin::DSL` 引入 DSL。
  - 子控制器通过 `menu_item`, `list_item_actions`, `list_actions`, `search_fields`, `default_actions`, `default_actions_html` 进行配置。
- 视图：
  - 使用 `admin_search_form`, `admin_list_actions`, `admin_list_item_actions`, `admin_bulk_checkbox`, `admin_has_bulk_actions?` 等 Helper。
- 生成资源视图：

```bash
bin/rails g fast_admin:resource post
```

会生成 `app/views/admin/posts/index.html.erb`，包含搜索、批量操作、列表项动作与条件多选框。

## 开发注意

- 开发环境自动重载时通过 `FastAdmin::Registry.reset!` 防止菜单重复。
- 若项目已有本地 `lib/fast_admin`，建议在初始化文件中忽略其自动加载以使用 gem 内实现。

## 配置

挂载路径（默认 `/admin`）：

```ruby
FastAdminRails.configure do |c|
  # FastAdminRails.config
  c.mount_path = "/admin"
end
```

## 配置

通过以下方式自定义按钮样式与确认文案：

```ruby
FastAdmin.configure do |c|
  c.button_classes = {
    show:   "text-blue-600 hover:text-blue-800",
    edit:   "text-green-600 hover:text-green-800",
    delete: "text-red-600 hover:text-red-800"
  }
  c.confirm_texts = {
    delete: "确定要删除吗？"
  }
end
```


## 控制器示例与用法说明

下面示例基于 `Admin::PostsController`，展示常用 DSL 的组合用法（摘自宿主应用的实现）：

```ruby
class Admin::PostsController < Admin::BaseController
  # 隐藏默认的“删除”按钮；查看/编辑仍显示
  default_actions delete: false

  # 覆盖默认“编辑”按钮的 HTML（字符串或 Proc 都可；此处为 Proc）
  default_actions_html edit: ->(post) {
    link_to("编辑", edit_admin_post_path(post), class: "px-2 py-1 rounded bg-green-600 text-white hover:bg-green-700")
  }

  # 搜索表单字段配置（渲染使用 helper: admin_search_form）
  search_fields do
    search_field name: :title, type: :text, label: "标题", order: 1
    search_field name: :content, type: :text, label: "内容", order: 2
  end

  # 列表项展示字段配置（渲染使用 helper: admin_list_item_fields(record)）
  list_item_fields do
    list_item_field name: :id, label: "ID", order: 0
    list_item_field name: :title, label: "标题", order: 1
    list_item_field name: :content, label: "内容", order: 2
  end

  # 列表级别批量操作（渲染使用 helper: admin_list_actions）
  list_actions do
    list_action name: "批量审核", path: :bulk_approve_admin_posts_path, method: :patch, order: 1,
      css_class: "px-3 py-1 rounded bg-purple-600 text-white hover:bg-purple-700"
    list_action name: "批量删除", path: :bulk_destroy_admin_posts_path, method: :delete,
      confirm: "确定要删除所选吗？", order: 2,
      css_class: "px-3 py-1 rounded bg-red-600 text-white hover:bg-red-700"
  end

  # 菜单配置：不自动插入“列表管理”子项；添加一个“审核”子菜单
  menu_item name: "文章管理", icon: "article", order: 20, show_list_item: false,
    submenu: [ { name: "审核", path: :pending_admin_posts_path, order: 1 } ]

  # 列表项的自定义操作按钮（支持 route helper 的 symbol 或 Proc 路径）
  list_item_actions do
    action name: "审核",
           path: :approve_admin_post_path,
           method: :patch,
           order: 1,
           css_class: "text-purple-600 hover:text-purple-800"
  end

  # 额外的集合/成员路由声明，供自动路由绘制使用
  extra_routes do
    collection_route name: :pending, method: :get
    collection_route name: :bulk_approve, method: :patch
    collection_route name: :bulk_destroy, method: :delete
    member_route name: :approve, method: :patch
  end
end
```

### 说明与建议

- 默认按钮：`default_actions show:, edit:, delete:` 控制 查看/编辑/删除 的显示；`default_actions_html` 可覆盖其 HTML（字符串或 Proc，Proc 接收记录）。
- 搜索表单：在 index 视图使用 `admin_search_form` 渲染；参数统一通过 `params[:q]`（字段名为键）。
- 列表字段：使用 `admin_list_item_fields(record)` 渲染已配置的字段，支持 `formatter:` 自定义显示。
- 批量操作：使用 `admin_list_actions` 渲染；复选框通过 `admin_bulk_checkbox(record)` 生成，选中值会以 `ids[]` 提交。
- 自定义列表项动作：`path` 支持 route helper 的 symbol（如 `:approve_admin_post_path`）或 `->(record){ ... }`。
- 菜单：`menu_item` 的 `submenu` 内 `path` 可用 route helper symbol 或具体 URL；可通过 `show_list_item: false` 关闭自动插入的“列表管理”。
- 额外路由：通过 `extra_routes` 声明集合/成员动作，配合自动路由绘制（`FastAdmin::Routing.draw_admin`）使用。

## 用户模型集成

- 默认使用宿主应用的 `User` 模型。可通过配置覆盖：

```ruby
FastAdminRails.configure do |c|
  c.user_class_name = "User" # 或者 "Account" 等
end
```

- 若宿主未提供该模型，FastAdminRails 会回退到引擎内置模型 `FastAdminRails::User`，表名为 `fast_admin_users`，字段包含：
  - `email:string` 唯一非空
  - `nickname:string`
  - `password_digest:string` 非空（使用 `has_secure_password`）
  - `timestamps`

- 生成回退模型的表迁移：

```bash
bin/rails g fast_admin:user
bin/rails db:migrate
```

- 在管理端控制器中使用统一入口获取用户类：`FastAdminRails.user_class`

```ruby
class Admin::UsersController < Admin::BaseController
  menu_item name: "用户管理", icon: "users", order: 10

  search_fields do
    search_field name: :email, type: :text, label: "邮箱"
    search_field name: :nickname, type: :text, label: "昵称"
  end

  list_item_fields do
    list_item_field name: :email, label: "邮箱", order: 1
    list_item_field name: :nickname, label: "昵称", order: 2
  end

  def index
    @users = FastAdminRails.user_class.order(id: :desc).limit(50)
  end

  def new
    @user = FastAdminRails.user_class.new
  end

  def create
    @user = FastAdminRails.user_class.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "创建成功"
    else
      render :new
    end
  end

  private

  def user_params
    params.expect(admin_user: [:email, :nickname, :password])
  end
end
```

这样无论宿主提供 `User` 还是使用引擎内置 `FastAdminRails::User`，管理端都能一致运作。

## 管理端认证过滤（可选）

- 启用登录校验并配置登录页：

```ruby
FastAdminRails.configure do |c|
  c.require_authentication = true
  c.login_path_name = :admin_sessions_new_path   # 登录页路由 helper（可改为宿主自定义）
  c.session_user_key = :admin_user_id            # 会话中的用户 key
  c.skip_auth_controllers = [                    # 在这些控制器上跳过认证（可扩展或清空）
    "Admin::SessionsController",
    "Admin::RegistrationsController",
    "Admin::PasswordsController"
  ]
end
```

- BaseController 已内置：
  - `helper_method :current_admin_user`
  - `before_action :authenticate_admin!`（按配置启用）
  - 未登录则重定向至配置的登录页；支持 `main_app` 的 helper 解析与路径回退。

- 视图生成器：

```bash
bin/rails g fast_admin:user:views
```

会生成以下视图到宿主：
- `app/views/admin/sessions/new.html.erb`（登录）
- `app/views/admin/registrations/new.html.erb`（注册）
- `app/views/admin/passwords/new.html.erb`（找回密码）
- `app/views/admin/passwords/edit.html.erb`（重置密码）


