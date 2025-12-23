module FastAdminRails
  class Config
    attr_accessor :mount_path, :layout, :route_prefix, :dashboard_enabled

    def initialize
      @mount_path = "/admin"
      @layout = "admin"
      @route_prefix = "admin"
      @dashboard_enabled = true
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end
end
