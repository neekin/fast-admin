module FastAdmin
  module AdminHelper
    # 安全读取 FastAdmin 配置（宿主可能未定义 config）
    def fa_config
      return nil unless defined?(FastAdmin) && FastAdmin.respond_to?(:config)
      FastAdmin.config
    rescue
      nil
    end

    def fa_button_class(kind, default_class)
      cfg = fa_config
      return default_class unless cfg && cfg.respond_to?(:button_classes)
      cfg.button_classes[kind] || default_class
    end

    def fa_confirm_text(kind, default_text)
      cfg = fa_config
      return default_text unless cfg && cfg.respond_to?(:confirm_texts)
      cfg.confirm_texts[kind] || default_text
    end

    def fa_custom_action_default_class
      cfg = fa_config
      return "text-blue-600 hover:text-blue-800" unless cfg && cfg.respond_to?(:custom_action_default_class)
      cfg.custom_action_default_class || "text-blue-600 hover:text-blue-800"
    end
    # 顶部菜单渲染入口：在布局中调用 <%= admin_menu %>
    def admin_menu
      render partial: "admin/shared/memu"
    end

    def admin_menu_items
      controllers = (defined?(FastAdmin::Registry) ? FastAdmin::Registry.controllers : [])
      controllers = controllers.group_by { |k| k.name }.values.map(&:first)
      # 仅保留宿主 Admin 命名空间的控制器，过滤引擎控制器
      controllers = controllers.select { |klass| klass.name.present? && klass.name.start_with?("Admin::") }

      # 在开发环境（或 eager_load 关闭时），执行一次扫描补全未加载的控制器，并注册到 Registry
      if !Rails.application.config.eager_load
        Rails.application.eager_load!
        scanned = ActionController::Base.descendants.select do |klass|
          klass < Admin::BaseController && klass.name.present? && klass.name.start_with?("Admin::")
        end
        if defined?(FastAdmin::Registry)
          scanned.each { |k| FastAdmin::Registry.register(k) }
        end
        controllers = (controllers + scanned).group_by { |k| k.name }.values.map(&:first)
      elsif controllers.nil? || controllers.empty?
        # 在非开发但 Registry 为空的场景下，兜底扫描一次
        Rails.application.eager_load!
        controllers = ActionController::Base.descendants.select do |klass|
          klass < Admin::BaseController && klass.name.present? && klass.name.start_with?("Admin::")
        end
        if defined?(FastAdmin::Registry)
          controllers.each { |k| FastAdmin::Registry.register(k) }
        end
        controllers = controllers.group_by { |k| k.name }.values.map(&:first)
      end

      Rails.logger.debug("[FastAdmin] menu discovery controllers=#{controllers.map(&:name)}")
      items = controllers.map do |klass|
        class_name = klass.name
        resource   = class_name.demodulize.sub("Controller", "").underscore

        config = klass.menu_config
        # 路由辅助方法检测与调用（支持 main_app 前缀）
        def route_helper_available?(name)
          respond_to?(name) || (defined?(main_app) && main_app.respond_to?(name))
        end
        def call_route_helper(name, *args)
          if respond_to?(name)
            send(name, *args)
          elsif defined?(main_app) && main_app.respond_to?(name)
            main_app.send(name, *args)
          else
            raise NoMethodError, "undefined route helper #{name}"
          end
        end

        # 解析顶级 path：支持 symbol 的路由 helper
        index_path = config[:path]
        if index_path.is_a?(Symbol)
          begin
            index_path = call_route_helper(index_path)
          rescue NoMethodError
            index_path = nil
          end
        end
        # 计算 index_path 的健壮回退：优先 RESTful index，其次命名路由，最后 Admin 根路径
        if index_path.nil?
          begin
            index_path = url_for(controller: "admin/#{resource}", action: :index)
          rescue ActionController::UrlGenerationError, NoMethodError
            # 尝试资源集合路由，例如 posts => admin_posts_path
            prefix = (FastAdminRails.respond_to?(:config) ? FastAdminRails.config.route_prefix : "admin")
            plural_route = "#{prefix}_#{resource.pluralize}_path"
            if route_helper_available?(plural_route)
              index_path = call_route_helper(plural_route)
            elsif resource == "home"
              home_route = "#{prefix}_home_path"
              if route_helper_available?(home_route)
                index_path = call_route_helper(home_route)
              else
                begin
                  index_path = url_for(controller: "admin/home", action: :index)
                rescue
                  index_path = (FastAdminRails.respond_to?(:config) ? File.join(FastAdminRails.config.mount_path, "home") : "/admin/home")
                end
              end
            else
              index_path = (FastAdminRails.respond_to?(:config) ? FastAdminRails.config.mount_path : "/admin")
            end
          end
        end

        item = {
          name: config[:name] || resource.titleize,
          icon: config[:icon],
          order: config[:order] || 100,
          path: index_path,
          submenu: config[:submenu] || []
        }

        # 解析子菜单 path（支持 symbol 的路由 helper），并根据配置插入“列表管理”项
        item[:submenu] = item[:submenu].map do |subitem|
          subitem = subitem.dup
          if subitem[:path].is_a?(Symbol)
            begin
              subitem[:path] = send(subitem[:path])
            rescue NoMethodError
              next
            end
          end
          subitem
        end.compact

        if config[:show_list_item]
          list_item = {
            name: "列表管理",
            path: index_path,
            order: 0
          }
          item[:submenu].unshift(list_item)
        end

        item
      end

      items = items.sort_by { |item| item[:order] }
      Rails.logger.debug("[FastAdmin] menu items built=#{items.map { |i| { name: i[:name], path: i[:path] } }}")
      items
    end

    def admin_list_item_actions(record)
      controller_class = controller.class
      return "" unless controller_class < Admin::BaseController

      actions = []

      custom_actions = controller_class.list_item_actions_config
      custom_actions.each do |action_config|
        path = action_config[:path]
        if path.respond_to?(:call)
          path = path.call(record)
        elsif path.is_a?(Symbol)
          begin
            path = send(path, record)
          rescue NoMethodError
            next
          end
        end

        actions << {
          name: action_config[:name],
          path: path,
          method: action_config[:method] || :get,
          confirm: action_config[:confirm],
          css_class: action_config[:css_class] || fa_custom_action_default_class,
          icon: action_config[:icon]
        }
      end

      defaults_cfg = controller_class.respond_to?(:default_actions_config) ? controller_class.default_actions_config : { show: true, edit: true, delete: true }
      defaults_html = controller_class.respond_to?(:default_actions_html_config) ? controller_class.default_actions_html_config : {}

      # 逐项计算，避免单个路由缺失导致全部默认按钮消失
      # 查看
      if defaults_cfg[:show]
        if defaults_html[:show]
          actions << { html: defaults_html[:show], order: 100 }
        else

          begin
            resource_key = record.class.name.demodulize.underscore
            prefix = (FastAdminRails.respond_to?(:config) ? FastAdminRails.config.route_prefix : "admin")
            show_path = send("#{prefix}_#{resource_key}_path", record)
            Rails.logger.debug("[FastAdmin] default show resolved via helper for #{record.class}(id=#{record.id}): #{show_path}")
            css_show = fa_button_class(:show, "text-blue-600 hover:text-blue-800")
            actions << { name: "查看", path: show_path, method: :get, css_class: css_show, order: 100 }
          rescue NoMethodError, NameError, ActionController::UrlGenerationError => e
            Rails.logger.warn("[FastAdmin] default show helper failed for #{record.class}(id=#{record.id}): #{e.class} - #{e.message}")
            # 路由 helper 不可用时，回退到 url_for
            begin
              resource = controller_class.name.demodulize.sub("Controller", "").underscore
              Rails.logger.debug("[FastAdmin] attempting url_for fallback: controller=admin/#{resource} id=#{record.id}")
              show_path = url_for(controller: "admin/#{resource}", action: :show, id: record.id)
              Rails.logger.debug("[FastAdmin] default show resolved via url_for for #{record.class}(id=#{record.id}): #{show_path}")
              css_show = fa_button_class(:show, "text-blue-600 hover:text-blue-800")
              actions << { name: "查看", path: show_path, method: :get, css_class: css_show, order: 100 }
            rescue => e2
              Rails.logger.error("[FastAdmin] default show url_for fallback failed for #{record.class}(id=#{record.id}): #{e2.class} - #{e2.message}")
              # 忽略查看按钮
            end
          end
        end
      end

      # 编辑
      if defaults_cfg[:edit]
        if defaults_html[:edit]
          actions << { html: defaults_html[:edit], order: 101 }
        else
          begin
            resource_key = record.class.name.demodulize.underscore
            prefix = (FastAdminRails.respond_to?(:config) ? FastAdminRails.config.route_prefix : "admin")
            edit_path = send("edit_#{prefix}_#{resource_key}_path", record)
            css_edit = fa_button_class(:edit, "text-green-600 hover:text-green-800")
            actions << { name: "编辑", path: edit_path, method: :get, css_class: css_edit, order: 101 }
          rescue NoMethodError, NameError, ActionController::UrlGenerationError
            # 路由 helper 不可用时，回退到 url_for
            begin
              resource = controller_class.name.demodulize.sub("Controller", "").underscore
              edit_path = url_for(controller: "admin/#{resource}", action: :edit, id: record.id)
              css_edit = fa_button_class(:edit, "text-green-600 hover:text-green-800")
              actions << { name: "编辑", path: edit_path, method: :get, css_class: css_edit, order: 101 }
            rescue
              # 忽略编辑按钮
            end
          end
        end
      end

      # 删除
      if defaults_cfg[:delete]
        if defaults_html[:delete]
          actions << { html: defaults_html[:delete], order: 102 }
        else
          begin
            resource_key = record.class.name.demodulize.underscore
            prefix = (FastAdminRails.respond_to?(:config) ? FastAdminRails.config.route_prefix : "admin")
            destroy_path = send("#{prefix}_#{resource_key}_path", record)
            css_delete = fa_button_class(:delete, "text-red-600 hover:text-red-800")
            confirm_delete = fa_confirm_text(:delete, "确定要删除吗？")
            actions << { name: "删除", path: destroy_path, method: :delete, confirm: confirm_delete, css_class: css_delete, order: 102 }
          rescue NoMethodError, NameError, ActionController::UrlGenerationError
            # 路由 helper 不可用时，回退到 url_for
            begin
              resource = controller_class.name.demodulize.sub("Controller", "").underscore
              destroy_path = url_for(controller: "admin/#{resource}", action: :destroy, id: record.id)
              css_delete = fa_button_class(:delete, "text-red-600 hover:text-red-800")
              confirm_delete = fa_confirm_text(:delete, "确定要删除吗？")
              actions << { name: "删除", path: destroy_path, method: :delete, confirm: confirm_delete, css_class: css_delete, order: 102 }
            rescue
              # 忽略删除按钮
            end
          end
        end
      end

      actions = actions.sort_by { |a| a[:order] || 100 }
      render partial: "admin/shared/list_item_actions", locals: { actions: actions, record: record }
    end

    def admin_search_form
      controller_class = controller.class
      return "" unless controller_class < Admin::BaseController

      fields = controller_class.search_fields_config
      return "" if fields.empty?

      resource = controller_class.name.demodulize.sub("Controller", "").underscore
      index_path = url_for(controller: "admin/#{resource}", action: :index)

      render partial: "admin/shared/search_form", locals: { fields: fields, index_path: index_path }
    end

    def admin_list_actions
      controller_class = controller.class
      return "" unless controller_class < Admin::BaseController

      actions = controller_class.list_actions_config
      return "" if actions.empty?

      resolved = []
      actions.each do |a|
        path = a[:path]
        if path.is_a?(Symbol)
          begin
            path = send(path)
          rescue NoMethodError
            next
          end
        end
        resolved << a.merge(path: path)
      end

      render partial: "admin/shared/list_actions", locals: { actions: resolved }
    end

    def admin_has_bulk_actions?
      controller_class = controller.class
      return false unless controller_class < Admin::BaseController
      actions = controller_class.list_actions_config
      actions.any?
    end

    def admin_bulk_checkbox(record)
      return "" unless admin_has_bulk_actions?
      tag.input(type: "checkbox", name: "ids[]", value: record.id, form: "bulk_actions_form", class: "mr-2")
    end

    # Render list item fields based on controller-level DSL configuration
    def admin_list_item_fields(record)
      controller_class = controller.class
      return record.to_s unless controller_class < Admin::BaseController

      fields = controller_class.respond_to?(:list_item_fields_config) ? controller_class.list_item_fields_config : []
      return record.to_s if fields.empty?

      render partial: "admin/shared/list_item_fields", locals: { record: record, fields: fields }
    end
  end
end
