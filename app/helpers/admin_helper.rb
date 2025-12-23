module AdminHelper
  # 返回需要在菜单中显示的 Admin 控制器列表
  # 约定：继承自 Admin::BaseController 的控制器，都会出现在菜单中
  # 每个控制器可以通过 menu_item 类方法配置菜单项（name, icon, order, path, submenu）
  def admin_menu_items
    # 优先使用注册表收集的 Admin 控制器；若为空，开发环境回退到 eager_load + descendants 扫描
    controllers = (defined?(FastAdmin::Registry) ? FastAdmin::Registry.controllers : [])
    # 额外去重：按类名唯一化，避免开发重载导致重复
    controllers = controllers.group_by { |k| k.name }.values.map(&:first)

    if controllers.nil? || controllers.empty?
      # 在非 eager_load 环境下，确保类已加载
      Rails.application.eager_load! unless Rails.application.config.eager_load

      controllers = ActionController::Base.descendants.select do |klass|
        klass < Admin::BaseController && klass.name.present?
      end

      # 将扫描到的控制器补注册进 Registry，便于后续使用
      if defined?(FastAdmin::Registry)
        controllers.each { |k| FastAdmin::Registry.register(k) }
      end

      # 再次去重一次确保唯一
      controllers = controllers.group_by { |k| k.name }.values.map(&:first)
    end

    items = controllers.map do |klass|
      class_name = klass.name
      resource   = class_name.demodulize.sub("Controller", "").underscore

      # 从控制器类读取菜单配置
      config = klass.menu_config

      index_path = config[:path] || url_for(controller: "/admin/#{resource}", action: :index)

      item = {
        name: config[:name] || resource.titleize,
        icon: config[:icon],
        order: config[:order] || 100,
        path: index_path,
        submenu: config[:submenu] || []
      }

      # 处理子菜单中的 path（如果是 symbol，转换为实际路径）
      if item[:submenu].any?
        item[:submenu] = item[:submenu].map do |subitem|
          subitem = subitem.dup
          if subitem[:path].is_a?(Symbol)
            # 如果是路由 helper symbol，尝试调用
            begin
              subitem[:path] = send(subitem[:path])
            rescue NoMethodError
              # 如果路由不存在，跳过这个子菜单项
              next
            end
          end
          subitem
        end.compact

        # 如果配置了显示列表管理项，自动添加"列表管理"作为第一个子菜单项
        if config[:show_list_item]
          list_item = {
            name: "列表管理",
            path: index_path,
            order: 0
          }
          item[:submenu].unshift(list_item)
        end
      end

      item
    end

    items.sort_by { |item| item[:order] }
  end

  # 渲染列表项的操作按钮（包括默认的查看、编辑、删除和自定义按钮）
  # 用法：
  #   <%= admin_list_item_actions(post) %>
  def admin_list_item_actions(record)
    controller_class = controller.class
    return "" unless controller_class < Admin::BaseController

    actions = []

    # 获取自定义操作按钮配置
    custom_actions = controller_class.list_item_actions_config

    # 添加自定义按钮
    custom_actions.each do |action_config|
      path = action_config[:path]
      # 如果 path 是 lambda/proc，调用它传入 record
      if path.respond_to?(:call)
        path = path.call(record)
      elsif path.is_a?(Symbol)
        # 如果是 symbol，尝试调用路由 helper
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
        css_class: action_config[:css_class] || (defined?(FastAdmin) ? FastAdmin.config.custom_action_default_class : "text-blue-600 hover:text-blue-800"),
        icon: action_config[:icon]
      }
    end

    # 添加默认按钮：查看、编辑、删除（受控制器 default_actions 配置影响）
    resource_name = controller_class.name.demodulize.sub("Controller", "").underscore
    resource_path_helper = "admin_#{resource_name.singularize}_path"
    defaults_cfg = controller_class.respond_to?(:default_actions_config) ? controller_class.default_actions_config : { show: true, edit: true, delete: true }
    defaults_html = controller_class.respond_to?(:default_actions_html_config) ? controller_class.default_actions_html_config : {}

    begin
      show_path = send(resource_path_helper, record)
      edit_path = send("edit_#{resource_path_helper}", record)
      destroy_path = send(resource_path_helper, record)

      if defaults_cfg[:show]
        if defaults_html[:show]
          actions << { html: defaults_html[:show], order: 100 }
        else
          css_show = defined?(FastAdmin) ? FastAdmin.config.button_classes[:show] : "text-blue-600 hover:text-blue-800"
          actions << { name: "查看", path: show_path, method: :get, css_class: css_show, order: 100 }
        end
      end
      if defaults_cfg[:edit]
        if defaults_html[:edit]
          actions << { html: defaults_html[:edit], order: 101 }
        else
          css_edit = defined?(FastAdmin) ? FastAdmin.config.button_classes[:edit] : "text-green-600 hover:text-green-800"
          actions << { name: "编辑", path: edit_path, method: :get, css_class: css_edit, order: 101 }
        end
      end
      if defaults_cfg[:delete]
        if defaults_html[:delete]
          actions << { html: defaults_html[:delete], order: 102 }
        else
          css_delete = defined?(FastAdmin) ? FastAdmin.config.button_classes[:delete] : "text-red-600 hover:text-red-800"
          confirm_delete = defined?(FastAdmin) ? FastAdmin.config.confirm_texts[:delete] : "确定要删除吗？"
          actions << { name: "删除", path: destroy_path, method: :delete, confirm: confirm_delete, css_class: css_delete, order: 102 }
        end
      end
    rescue NoMethodError
      # 如果路由不存在，跳过默认按钮
    end

    render partial: "admin/shared/list_item_actions", locals: { actions: actions, record: record }
  end

  # 渲染基于控制器配置的搜索表单
  # 使用 GET 到资源的 index 路径，参数命名为 q[field]
  def admin_search_form
    controller_class = controller.class
    return "" unless controller_class < Admin::BaseController

    fields = controller_class.search_fields_config
    return "" if fields.empty?

    # 计算 index 路径
    resource = controller_class.name.demodulize.sub("Controller", "").underscore
    index_path = url_for(controller: "/admin/#{resource}", action: :index)

    render partial: "admin/shared/search_form", locals: { fields: fields, index_path: index_path }
  end

  # 渲染列表级别的批量操作（基于控制器配置的 list_actions）
  # 设计：使用单一 form（id: bulk_actions_form），各行复选框可通过 form="bulk_actions_form" 参与提交
  def admin_list_actions
    controller_class = controller.class
    return "" unless controller_class < Admin::BaseController

    actions = controller_class.list_actions_config
    return "" if actions.empty?

    # 解析 path（支持 symbol 的路由 helper）
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

  # 是否存在列表级批量操作，用于决定是否显示行选择框
  def admin_has_bulk_actions?
    controller_class = controller.class
    return false unless controller_class < Admin::BaseController
    actions = controller_class.list_actions_config
    actions.any?
  end

  # 行内复选框（仅在存在批量操作时渲染），用于提交到 bulk_actions_form
  def admin_bulk_checkbox(record)
    return "" unless admin_has_bulk_actions?
    tag.input(type: "checkbox", name: "ids[]", value: record.id, form: "bulk_actions_form", class: "mr-2")
  end
end
