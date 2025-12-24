module FastAdminRails
  module Authorization
    # Authorize current action against record or class.
    # For Pundit, calls policy(action?). For Cancancan, calls authorize!.
    def fa_authorize!(action, record = nil)
      adapter = (FastAdminRails.config.authorization_adapter || :none).to_sym
      case adapter
      when :none
        true
      when :pundit
        require_pundit!
        rec = record || fa_default_policy_target
        query = (action.to_s + "?").to_sym
        policy = FastAdminRails::PolicyFactory.build(current_admin_user, rec)
        allowed = policy.respond_to?(query) ? policy.public_send(query) : false
        raise Pundit::NotAuthorizedError, "not allowed to #{action} #{rec.inspect}" unless allowed
        true
      when :cancancan
        require_cancancan!
        rec = record || fa_default_policy_target
        if respond_to?(:current_ability) && current_ability
          current_ability.authorize!(action.to_sym, rec)
        else
          authorize!(action.to_sym, rec)
        end
        true
      else
        true
      end
    end

    # Apply policy scope to collection.
    def fa_policy_scope(scope)
      adapter = (FastAdminRails.config.authorization_adapter || :none).to_sym
      case adapter
      when :pundit
        # 默认返回 scope；可在宿主侧提供自定义 PolicyScope 时覆盖
        scope
      when :cancancan
        require_cancancan!
        if respond_to?(:current_ability) && current_ability
          scope.accessible_by(current_ability)
        else
          scope
        end
      else
        scope
      end
    end

    # Infer resource class from controller name, e.g. Admin::PostsController -> Post
    def fa_resource_class
      name = self.class.name.demodulize.sub("Controller", "")
      name.singularize.classify.safe_constantize
    rescue
      nil
    end

    # Default target for policy checks (class for collection/new/create; record for member actions
    def fa_default_policy_target
      klass = fa_resource_class
      return klass unless [ :show, :edit, :update, :destroy ].include?(action_name.to_sym)
      return klass unless klass && params[:id].present?
      begin
        klass.find(params[:id])
      rescue
        klass
      end
    end

    def fa_auto_authorize!
      return unless FastAdminRails.config.auto_authorize
      return if FastAdminRails.config.skip_authz_controllers.include?(self.class.name)
      klass = fa_resource_class
      return true unless klass
      action = action_name.to_sym
      fa_authorize!(action, nil)
    end

    private

    def require_pundit!
      raise NameError, "pundit gem is not available" unless defined?(Pundit)
    end

    def require_cancancan!
      unless defined?(CanCan) || defined?(CanCan::Ability)
        raise NameError, "cancancan gem is not available"
      end
    end
  end
end
