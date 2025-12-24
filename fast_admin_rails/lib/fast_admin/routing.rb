module FastAdmin
  module Routing
    # Auto draw admin resources for controllers inheriting Admin::BaseController.
    # Extra collection/member routes are read from controller DSL.
    def self.draw_admin(mapper, path: nil, as: :admin, use_scope: false)
      controllers = []
      begin
        controllers = (defined?(FastAdmin::Registry) ? FastAdmin::Registry.controllers : [])
        controllers = controllers.group_by { |k| k.name }.values.map(&:first)
        if controllers.nil? || controllers.empty?
          Rails.application.eager_load!
          controllers = ActionController::Base.descendants.select do |klass|
            klass < Admin::BaseController && klass.name.present?
          end
        end
      rescue => e
        Rails.logger.warn("[FastAdmin] routing discovery failed: #{e.class} - #{e.message}")
      end

      # Avoid duplicates
      controllers = controllers.group_by { |k| k.name }.values.map(&:first)
      # Only draw host Admin namespace controllers; skip gem engine controllers
      controllers = controllers.select { |k| k.name.start_with?("Admin::") }

      resolved_path = path || (FastAdminRails.respond_to?(:config) ? FastAdminRails.config.mount_path : "/admin")
      mapper.instance_eval do
        draw_block = proc do
          controllers.each do |klass|
            resource = klass.name.demodulize.sub("Controller", "").underscore
            # Skip Home controller for resourceful routes; set scoped root
            if resource == "home"
              # Provide explicit /home route under the scoped path
              get "/home", to: "home#index"
              next
            end
            resources resource.to_sym do
              extra = klass.respond_to?(:extra_routes_config) ? klass.extra_routes_config : { collection: [], member: [] }
              if extra[:collection].any?
                collection do
                  extra[:collection].each do |r|
                    send(r[:method], r[:name])
                  end
                end
              end
              if extra[:member].any?
                member do
                  extra[:member].each do |r|
                    send(r[:method], r[:name])
                  end
                end
              end
            end
          end

          # Draw auth routes regardless of inheritance, to allow engine-provided controllers
          resources :sessions, only: [ :new, :create, :destroy ]
          resources :registrations, only: [ :new, :create ]
          resources :passwords, only: [ :new, :create, :edit, :update ]
        end

        if use_scope
          draw_block.call
        else
          scope module: :admin, as: as, path: resolved_path do
            draw_block.call
          end
        end
      end
    end
  end
end
