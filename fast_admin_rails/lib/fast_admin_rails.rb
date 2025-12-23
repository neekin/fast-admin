# frozen_string_literal: true

require "rails"

require_relative "fast_admin/config"
require_relative "fast_admin/dsl"
require_relative "fast_admin/registry"
require_relative "fast_admin_rails/config"
require_relative "fast_admin_rails/engine"

module FastAdminRails
  # Configure FastAdminRails only (mount path etc.)
  def self.configure
    yield(FastAdminRails.config)
  end
end
