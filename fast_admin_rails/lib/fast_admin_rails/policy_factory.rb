module FastAdminRails
  module PolicyFactory
    # 返回策略类实例，优先使用已定义的 <Resource>Policy，否则构造动态策略类继承 ApplicationPolicy
    def self.build(user, record)
      klass = record.is_a?(Class) ? record : record.class
      policy_class_name = "#{klass.name.demodulize}Policy"
      policy_class = FastAdminRails::Policies.const_defined?(policy_class_name, false) ? FastAdminRails::Policies.const_get(policy_class_name) : nil
      unless policy_class
        policy_class = build_dynamic_policy_for(klass)
      end
      policy_class.new(user, record)
    end

    def self.build_dynamic_policy_for(klass)
      name = "#{klass.name.demodulize}Policy"
      FastAdminRails::Policies.const_set(name, Class.new(FastAdminRails::Policies::ApplicationPolicy))
    end
  end
end
