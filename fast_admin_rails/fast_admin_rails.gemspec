# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "fast_admin_rails"
  spec.version       = "0.1.0"
  spec.authors       = [ "Fast Admin" ]
  spec.email         = [ "dev@example.com" ]

  spec.summary       = "FastAdmin Rails engine and DSL for admin UIs"
  spec.description   = "Provides admin controller DSL, menu rendering, bulk actions, search forms, and generators for Rails apps."
  spec.homepage      = "https://example.com/fast_admin_rails"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "app/**/*", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "bcrypt", ">= 3.1"
end
