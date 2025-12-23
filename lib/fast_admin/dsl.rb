module FastAdmin
  module Dsl
    # Menu configuration
    def menu_item(name: nil, icon: nil, order: 100, path: nil, submenu: [], show_list_item: true)
      @menu_name = name
      @menu_icon = icon
      @menu_order = order
      @menu_path = path
      @menu_submenu = submenu
      @menu_show_list_item = show_list_item
    end

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

    # List item actions
    def list_item_actions(&block)
      @list_item_actions = []
      instance_eval(&block) if block_given?
      @list_item_actions
    end

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

    def list_item_actions_config
      (@list_item_actions || []).sort_by { |action| action[:order] }
    end

    # List-level bulk actions (operate on selected IDs)
    def list_actions(&block)
      @list_actions = []
      instance_eval(&block) if block_given?
      @list_actions
    end

    def list_action(name:, path:, method: :post, confirm: nil, order: 100, css_class: nil, icon: nil)
      @list_actions ||= []
      @list_actions << {
        name: name,
        path: path,
        method: method,
        confirm: confirm,
        order: order,
        css_class: css_class,
        icon: icon
      }
    end

    def list_actions_config
      (@list_actions || []).sort_by { |action| action[:order] }
    end

    # Default actions toggle
    def default_actions(show: true, edit: true, delete: true)
      @default_actions = { show: show, edit: edit, delete: delete }
    end

    def default_actions_config
      { show: true, edit: true, delete: true }.merge(@default_actions || {})
    end

    # Default actions HTML overrides
    def default_actions_html(show: nil, edit: nil, delete: nil)
      @default_actions_html = {
        show: show,
        edit: edit,
        delete: delete
      }.compact
    end

    def default_actions_html_config
      @default_actions_html || {}
    end

    # Search fields
    def search_fields(&block)
      @search_fields = []
      instance_eval(&block) if block_given?
      @search_fields
    end

    def search_field(name:, type: :text, label: nil, options: nil, order: 100)
      @search_fields ||= []
      @search_fields << {
        name: name,
        type: type,
        label: label,
        options: options,
        order: order
      }
    end

    def search_fields_config
      (@search_fields || []).sort_by { |f| f[:order] || 100 }
    end
  end
end
