class Admin::BaseController < AdminController
  # 引入 DSL（菜单、动作、默认按钮、搜索配置等）以提升内聚并方便未来抽取为 gem
  extend FastAdmin::Dsl
    # 覆盖默认 查看/编辑/删除 的 HTML
    # 值可以是字符串（HTML）或接收 record 的 proc：->(record) { ...HTML... }
    # 用法：
    #   default_actions_html edit: ->(post){ link_to("编辑", edit_admin_post_path(post), class: "btn") }
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


  # 注册所有继承自 Admin::BaseController 的控制器到 Registry，以降低耦合
  def self.inherited(subclass)
    super
    begin
      FastAdmin::Registry.register(subclass)
    rescue NameError
      # 如果 Registry 尚未加载（初始化阶段），忽略注册；稍后加载后仍可手动注册
    end
  end
end
