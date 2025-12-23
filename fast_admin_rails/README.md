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

