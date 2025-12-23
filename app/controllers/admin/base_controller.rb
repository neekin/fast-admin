class Admin::BaseController < AdminController
  class << self
    # 配置菜单项属性
    # 用法：
    #   class Admin::UsersController < Admin::BaseController
    #     menu_item name: "用户管理", icon: "users", order: 20
    #   end
    #
    #   支持二级菜单：
    #   class Admin::PostsController < Admin::BaseController
    #     menu_item name: "文章管理", icon: "article", order: 20,
    #       submenu: [
    #         { name: "文章列表", path: admin_posts_path, order: 1 },
    #         { name: "草稿箱", path: drafts_admin_posts_path, order: 2 }
    #       ]
    #   end
    #
    #   不显示自动添加的"列表管理"项：
    #   menu_item name: "文章管理", icon: "article", order: 20,
    #     submenu: [...],
    #     show_list_item: false
    def menu_item(name: nil, icon: nil, order: 100, path: nil, submenu: [], show_list_item: true)
      @menu_name = name
      @menu_icon = icon
      @menu_order = order
      @menu_path = path
      @menu_submenu = submenu
      @menu_show_list_item = show_list_item
    end

    # 读取菜单配置
    def menu_config
      {
        name: @menu_name,
        icon: @menu_icon,
        order: @menu_order || 100,
        path: @menu_path,
        submenu: (@menu_submenu || []).sort_by { |item| item[:order] || 100 },
        show_list_item: @menu_show_list_item.nil? ? true : @menu_show_list_item
      }
    end

    # 配置列表项的自定义操作按钮
    # 用法：
    #   class Admin::PostsController < Admin::BaseController
    #     list_item_actions do
    #       action name: "审核", path: ->(post) { approve_admin_post_path(post) }, method: :patch, order: 1
    #       action name: "拒绝", path: ->(post) { reject_admin_post_path(post) }, method: :patch, confirm: "确定要拒绝吗？", order: 2
    #     end
    #   end
    def list_item_actions(&block)
      @list_item_actions = []
      if block_given?
        instance_eval(&block)
      end
      @list_item_actions
    end

    # 定义单个操作按钮
    def action(name:, path:, method: :get, confirm: nil, order: 100, css_class: nil, icon: nil)
      @list_item_actions ||= []
      @list_item_actions << {
        name: name,
        path: path,
        method: method,
        confirm: confirm,
        order: order,
        css_class: css_class,
        icon: icon
      }
    end

    # 读取列表项操作配置
    def list_item_actions_config
      (@list_item_actions || []).sort_by { |action| action[:order] }
    end
  end
end


