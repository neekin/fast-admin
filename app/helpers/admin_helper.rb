module AdminHelper
  # 返回需要在菜单中显示的 Admin 控制器列表
  # 约定：继承自 Admin::BaseController 的控制器，都会出现在菜单中
  # 每个控制器可以通过 menu_item 类方法配置菜单项（name, icon, order, path, submenu）
  def admin_menu_items
    # 确保所有控制器类都被加载（开发模式下很重要）
    Rails.application.eager_load! unless Rails.application.config.eager_load

    # 使用 ActionController::Base.descendants 查找所有控制器
    # 然后筛选出继承自 Admin::BaseController 的
    controllers = ActionController::Base.descendants.select do |klass|
      klass < Admin::BaseController && klass.name.present?
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
        css_class: action_config[:css_class] || "text-blue-600 hover:text-blue-800",
        icon: action_config[:icon]
      }
    end

    # 添加默认按钮：查看、编辑、删除
    resource_name = controller_class.name.demodulize.sub("Controller", "").underscore
    resource_path_helper = "admin_#{resource_name.singularize}_path"
    
    begin
      show_path = send(resource_path_helper, record)
      edit_path = send("edit_#{resource_path_helper}", record)
      destroy_path = send(resource_path_helper, record)
      
      actions << { name: "查看", path: show_path, method: :get, css_class: "text-blue-600 hover:text-blue-800", order: 100 }
      actions << { name: "编辑", path: edit_path, method: :get, css_class: "text-green-600 hover:text-green-800", order: 101 }
      actions << { name: "删除", path: destroy_path, method: :delete, confirm: "确定要删除吗？", css_class: "text-red-600 hover:text-red-800", order: 102 }
    rescue NoMethodError
      # 如果路由不存在，跳过默认按钮
    end

    render partial: "admin/shared/list_item_actions", locals: { actions: actions }
  end
end

