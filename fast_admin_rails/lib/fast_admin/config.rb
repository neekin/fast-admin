module FastAdmin
  class Config
    attr_accessor :default_show_list_item,
                  :button_classes,
                  :confirm_texts,
                  :custom_action_default_class

    def initialize
      @default_show_list_item = true
      @button_classes = {
        show: "text-blue-600 hover:text-blue-800",
        edit: "text-green-600 hover:text-green-800",
        delete: "text-red-600 hover:text-red-800"
      }
      @confirm_texts = {
        delete: "确定要删除吗？"
      }
      @custom_action_default_class = "text-blue-600 hover:text-blue-800"
    end
  end
end
