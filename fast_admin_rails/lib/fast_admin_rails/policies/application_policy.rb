module FastAdminRails
  module Policies
    class ApplicationPolicy
      attr_reader :user, :record

      def initialize(user, record)
        @user = user
        @record = record
      end

      # 默认动作（REST）统一判断权限码：admin:<resource>:<action>
      def index?; allowed?(:index); end
      def show?; allowed?(:show); end
      def new?; allowed?(:new); end
      def create?; allowed?(:create); end
      def edit?; allowed?(:edit); end
      def update?; allowed?(:update); end
      def destroy?; allowed?(:destroy); end

      # 可用于额外成员/集合动作：approve? 等
      def method_missing(name, *args)
        return allowed?(name) if name.to_s.end_with?("?")
        super
      end

      def respond_to_missing?(name, include_private = false)
        name.to_s.end_with?("?") || super
      end

      private

      def allowed?(action)
        code = permission_code(action)
        FastAdminRails::RBAC.allowed?(user, code)
      end

      def permission_code(action)
        res = resource_key
        "admin:#{res}:#{action}"
      end

      def resource_key
        klass = record.is_a?(Class) ? record : record.class
        klass.name.demodulize.underscore
      end
    end
  end
end
