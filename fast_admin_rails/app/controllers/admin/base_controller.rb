module Admin
  # Gem 提供的 Admin 基类：直接继承宿主 ApplicationController，避免耦合
  class BaseController < ::ApplicationController
    layout -> { FastAdminRails.config.layout }
    # 使类具备 DSL（menu_item、list_item_actions、default_actions 等）
    class << self
      include FastAdmin::DSL
    end

    # 子类注册到 Registry，并确保 DSL 方法可用
    def self.inherited(subclass)
      super
      begin
        FastAdmin::Registry.register(subclass)
        subclass.extend(FastAdmin::DSL)
      rescue NameError
        # 初始化时未加载也可忽略
      end
    end
  end
end
