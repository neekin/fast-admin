class Admin::HomeController < Admin::BaseController
    menu_item name: "首页", icon: "article", order: 30, show_list_item: false

  def index
  end
end
