# Load FastAdmin from local gem
require "fast_admin_rails"
require "fast_admin/routing"

# Configure mount path to avoid conflict with host app's admin namespace
FastAdminRails.configure do |c|
  # Use custom mount path and route helper prefix; can be changed anytime
  c.mount_path = "/fa-admin"
  c.route_prefix = :admin.to_s
  # Disable engine dashboard routes; host app can provide its own
  c.dashboard_enabled = false
  # Enable authorization via Pundit (or switch to :cancancan)
  c.authorization_adapter = :pundit
  # Optionally auto-authorize RESTful actions (will infer resource class)
  c.auto_authorize = true
end

# Avoid Zeitwerk autoloading generator templates under lib/generators
Rails.autoloaders.main.ignore(Rails.root.join("lib/generators"))

# Prefer gem code over local lib to avoid constant duplication
Rails.autoloaders.main.ignore(Rails.root.join("lib/fast_admin.rb"))
Rails.autoloaders.main.ignore(Rails.root.join("lib/fast_admin"))

# Reset controller registry on each code reload to avoid duplicates in dev
if defined?(ActiveSupport::Reloader)
  ActiveSupport::Reloader.to_prepare do
    begin
      FastAdmin::Registry.reset!
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
