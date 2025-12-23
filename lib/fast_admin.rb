require_relative "fast_admin/config"
require_relative "fast_admin/dsl"

module FastAdmin
  class << self
    def config
      @config ||= FastAdmin::Config.new
    end

    def configure
      yield(config)
    end
  end
end
