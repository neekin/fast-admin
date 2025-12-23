# Copilot Instructions for Fast Admin (Rails 8)

These instructions help AI coding agents work productively in this Rails admin app. Focus on the concrete conventions and workflows used here.

## Architecture & Conventions

- Admin namespace: All admin controllers inherit from `Admin::BaseController` and use custom DSLs for navigation and list actions. The base controller is provided by the gem at [fast_admin_rails/app/controllers/admin/base_controller.rb](fast_admin_rails/app/controllers/admin/base_controller.rb) and loaded via [config/initializers/fast_admin.rb](config/initializers/fast_admin.rb).
- Discovery: Controllers auto-register via `Admin::BaseController.inherited` into `FastAdmin::Registry` ([fast_admin_rails/lib/fast_admin/registry.rb](fast_admin_rails/lib/fast_admin/registry.rb)); menu rendering uses this registry rather than global eager_load scans.
 - Engine: Provided by the local gem at [fast_admin_rails/lib/fast_admin_rails/engine.rb](fast_admin_rails/lib/fast_admin_rails/engine.rb) and loaded via [config/initializers/fast_admin.rb](config/initializers/fast_admin.rb) with `require "fast_admin_rails"`.
- Menu DSL:
  - Define menu metadata in controllers via `menu_item name:, icon:, order:, path:, submenu:, show_list_item:`.
  - The menu is rendered by `admin_menu_items` in [fast_admin_rails/app/helpers/fast_admin/admin_helper.rb](fast_admin_rails/app/helpers/fast_admin/admin_helper.rb) and the partial [fast_admin_rails/app/views/admin/shared/_memu.html.erb](fast_admin_rails/app/views/admin/shared/_memu.html.erb).
  - Route symbols resolve via helper or `main_app` with fallback to URL construction under the configured mount path.
  - Submenu `path` can be a route helper symbol (e.g. `:pending_admin_posts_path`) or a concrete URL; route symbols are resolved in helper.
  - If `show_list_item` is true (default), a "列表管理" submenu item for the controller index is auto-inserted.
- List item actions DSL:
  - In a controller, wrap custom buttons in `list_item_actions do ... end`, and add each `action name:, path:, method:, confirm:, order:, css_class:, icon:`.
  - `path` can be a proc `->(record){ ... }` or a route helper symbol; defaults exist for 查看/编辑/删除 buttons.
  - Rendering uses [fast_admin_rails/app/views/admin/shared/_list_item_actions.html.erb](fast_admin_rails/app/views/admin/shared/_list_item_actions.html.erb).
  - Toggle default 查看/编辑/删除 buttons via `default_actions show:, edit:, delete:` in the controller (e.g., `default_actions show: true, edit: false, delete: false`).
  - Override default button HTML via `default_actions_html show:, edit:, delete:`; values can be strings or procs receiving the record. Example:
    ```ruby
    default_actions_html edit: ->(post){ link_to("编辑", edit_admin_post_path(post), class: "btn btn-primary") }
    ```
- List bulk actions DSL:
  - Configure page-level actions via `list_actions do; list_action name:, path:, method:, confirm:, order:, css_class:, icon:; end`.
  - Helper `admin_list_actions` renders buttons using [fast_admin_rails/app/views/admin/shared/_list_actions.html.erb](fast_admin_rails/app/views/admin/shared/_list_actions.html.erb); selected IDs must be provided by checkboxes named `ids[]` with `form="bulk_actions_form"`.
  - Example:
    - Generator:
      - Install initializer via `rails g fast_admin:install` (writes [config/initializers/fast_admin.rb](config/initializers/fast_admin.rb)).
      - Scaffold admin index via `rails g fast_admin:resource <name>`; creates [app/views/admin/<name_plural>/index.html.erb](app/views/admin/<name_plural>/index.html.erb) with:
        - `admin_search_form`, `admin_list_actions`
        - Conditional row checkbox via `admin_bulk_checkbox(record)`
        - `admin_list_item_actions(record)`
    ```ruby
    class Admin::PostsController < Admin::BaseController
      list_actions do
        list_action name: "批量审核", path: :bulk_approve_admin_posts_path, method: :patch
        list_action name: "批量删除", path: :bulk_destroy_admin_posts_path, method: :delete, confirm: "确定要删除所选吗？"
      end
    end
    ```
- Search form DSL:
  - Configure fields via `search_fields do; search_field name:, type:, label:, options:, order:; end` in a controller.
  - Helper `admin_search_form` renders GET form using [fast_admin_rails/app/views/admin/shared/_search_form.html.erb](fast_admin_rails/app/views/admin/shared/_search_form.html.erb); params are under `q[field]`.
  - Example:
    ```ruby
    class Admin::PostsController < Admin::BaseController
      search_fields do
        search_field name: :title, type: :text, label: "标题"
        search_field name: :status, type: :select, label: "状态", options: [["草稿","draft"],["待审","pending"]]
      end
    end
    ```
- Strong parameters: Use the Rails 8 `params.expect` pattern in controllers (e.g., `params.expect(admin_post: [:title, :content])`). Prefer this over `require/permit`.
- Routing: Admin resource routes are auto-drawn from controllers inheriting `Admin::BaseController` via `FastAdmin::Routing.draw_admin`. See [config/routes.rb](config/routes.rb).
- Layouts & bundles:
  - Admin layout includes `admin.css` and `admin.js`. See [app/views/layouts/admin.html.erb](app/views/layouts/admin.html.erb).
  - Application layout includes `application.css` and `application.js`. See [app/views/layouts/application.html.erb](app/views/layouts/application.html.erb).

## Frontend (JS/CSS) Pipeline

- JS bundling: `esbuild` bundles entry points from `app/javascript` to `app/assets/builds` with ESM format. Script: `yarn build`.
- CSS: Tailwind CLI v4 builds from `app/assets/stylesheets/*tailwind.css` to `app/assets/builds/*.css`.
- Precompile targets: Declared in [config/initializers/assets.rb](config/initializers/assets.rb) as `application.js/css` and `admin.js/css`.
- Hotwire: Uses Turbo and Stimulus.
  - Stimulus manifests live at [app/javascript/controllers/index.js](app/javascript/controllers/index.js) and [app/javascript/admin/controllers/index.js](app/javascript/admin/controllers/index.js).
  - Generate/update with `./bin/rails stimulus:manifest:update`; new controllers go under the respective `controllers/` dir.

- DSL Module:
  - Controller-level DSL methods live in `FastAdmin::DSL` ([fast_admin_rails/lib/fast_admin/dsl.rb](fast_admin_rails/lib/fast_admin/dsl.rb)); `Admin::BaseController` extends it.

## Dev Workflow (macOS)

- Server: `bin/rails server` (Procfile.dev also supports `env RUBY_DEBUG_OPEN=true`).
- Watchers:
  - JS: `yarn build --watch`.
  - CSS: `npm run build:css:watch` (runs both app/admin watchers via `concurrently`).
- One-shot builds:
  - JS: `yarn build`
  - CSS (all): `npm run build:css`
- Optional: If using Foreman, `foreman start -f Procfile.dev` to run server + watchers together.

## Data & Tasks

- DB: SQLite3 by default. Typical setup: `bin/rails db:setup` or `bin/rails db:create db:migrate`.
- Example model/table: `admin_posts` (see migration [db/migrate/20251223170803_create_admin_posts.rb](db/migrate/20251223170803_create_admin_posts.rb)).

## Production (Docker)

- Build: `docker build -t fast_admin .`
- Run: `docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value> --name fast_admin fast_admin`
- Notes: Multi-stage build precompiles assets; Thruster + Puma used in `CMD`.

## Patterns & Examples

- New admin controller:
  - Inherit from `Admin::BaseController` and declare a menu:
    ```ruby
    class Admin::UsersController < Admin::BaseController
      menu_item name: "用户管理", icon: "users", order: 10,
        submenu: [ { name: "待审核", path: :pending_admin_users_path, order: 1 } ]

      list_item_actions do
        action name: "禁用", path: ->(user){ disable_admin_user_path(user) }, method: :patch, order: 1
      end
    end
    ```
- Use route helper symbols in submenu or actions; the helper will resolve them. If the route is missing, it's skipped.
- When adding new JS/CSS entry points, ensure they're emitted to `app/assets/builds` and precompiled in `assets.rb`; include in the relevant layout via `stylesheet_link_tag`/`javascript_include_tag`.

### List Item Fields DSL
- Control which record fields show on list pages:
  - Controller: `list_item_fields do; list_item_field name:, label:, formatter:, order:; end`.
  - Render via helper: `admin_list_item_fields(record)` using [fast_admin_rails/app/views/admin/shared/_list_item_fields.html.erb](fast_admin_rails/app/views/admin/shared/_list_item_fields.html.erb).
  - Example:
    ```ruby
    class Admin::PostsController < Admin::BaseController
      list_item_fields do
        list_item_field name: :title, label: "标题", order: 1
        list_item_field name: :content, label: "内容", order: 2
      end
    end
    ```

### Auto Routing & Mounting
- Recommended in [config/routes.rb](config/routes.rb): mount engine and auto-draw host admin resources under the same prefix with block flexibility:
  ```ruby
  scope path: "/fa-admin", as: :admin, module: :admin do
    mount FastAdminRails::Engine => "/"
    FastAdmin::Routing.draw_admin(self, use_scope: true, as: :admin)
    # Add extra routes here under the same prefix
  end
  ```
- Or without scope block:
  ```ruby
  mount FastAdminRails::Engine => FastAdminRails.config.mount_path
  FastAdmin::Routing.draw_admin(self, path: FastAdminRails.config.mount_path, as: :admin)
  ```
- Extra routes in controllers via DSL:
  - `extra_routes do; collection_route name:, method:; member_route name:, method:; end`
  - Example:
    ```ruby
    class Admin::PostsController < Admin::BaseController
      extra_routes do
        collection_route name: :pending, method: :get
        collection_route name: :bulk_approve, method: :patch
        collection_route name: :bulk_destroy, method: :delete
        member_route name: :approve, method: :patch
      end
    end
    ```

## Tooling

- Security & static analysis (optional): `bundle exec bundler-audit`, `bundle exec brakeman`, `bundle exec rubocop`.
- Hotwire/Turbo navigation: Default Turbo is enabled in both admin and application bundles.

## Configuration
- Generator:
  - Install initializer via `rails g fast_admin:install` (writes [config/initializers/fast_admin.rb](config/initializers/fast_admin.rb)).

- Global config: Change default button classes and confirm texts via `FastAdmin.configure` in [config/initializers/fast_admin.rb](config/initializers/fast_admin.rb).
  - Example:
    ```ruby
    FastAdmin.configure do |c|
      c.button_classes = { show: "...", edit: "...", delete: "..." }
      c.confirm_texts = { delete: "确定要删除吗？" }
    end
    ```

- Engine/admin config via `FastAdminRails.configure`:
  ```ruby
  FastAdminRails.configure do |c|
    c.mount_path = "/fa-admin"     # URL prefix for admin
    c.route_prefix = "admin"         # Helper prefix (e.g., admin_posts_path)
    c.layout = "admin"               # Layout used by Admin::BaseController
    c.dashboard_enabled = false       # Toggle engine dashboard routes
  end
  ```

## Gotchas

 - In development, `admin_menu_items` calls `Rails.application.eager_load!` to discover controllers; ensure your new admin controllers are loadable (file name/class naming matches Rails conventions). Only `Admin::` namespace controllers appear in the menu; engine controllers are filtered out.
- The list actions renderer distinguishes `link_to` vs `button_to` based on HTTP method (delete/patch/put use `button_to`). Provide `confirm` to show Turbo confirm dialogs.
 - Menu path resolution prefers route helpers (supports `main_app`), then falls back to URL construction under the configured `mount_path`.
 - Default 查看/编辑/删除 buttons resolve independently with route helper and `url_for` fallbacks; use `default_actions_html` to override per-button HTML when needed.

---
If any section is unclear or missing for your current task, please share the context (file paths, workflows), and we’ll refine these instructions.