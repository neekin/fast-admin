# Load FastAdmin core and engine
require Rails.root.join("lib/fast_admin")
require Rails.root.join("lib/fast_admin/engine")
begin
  require Rails.root.join("app/lib/fast_admin/registry")
rescue LoadError
  # If app/lib is not in autoload paths, this ensures Registry is loaded in this app.
end

# Avoid Zeitwerk autoloading generator templates under lib/generators
Rails.autoloaders.main.ignore(Rails.root.join("lib/generators"))

# Reset controller registry on each code reload to avoid duplicates in dev
if defined?(ActiveSupport::Reloader)
  ActiveSupport::Reloader.to_prepare do
    begin
      FastAdmin::Registry.reset
    rescue NameError
      # Registry may not be loaded yet
    end
  end
end

# Configure FastAdmin defaults (optional)
# FastAdmin.configure do |c|
#   c.default_show_list_item = true
#   c.button_classes = {
#     show:   "text-blue-600 hover:text-blue-800",
#     edit:   "text-green-600 hover:text-green-800",
#     delete: "text-red-600 hover:text-red-800"
#   }
#   c.confirm_texts = {
#     delete: "确定要删除吗？"
#   }
#   c.custom_action_default_class = "text-blue-600 hover:text-blue-800"
# end
