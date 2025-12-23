module FastAdmin
  module Registry
    @controllers_by_name = {}
    class << self
      def controllers
        @controllers_by_name.values
      end

      def register(controller)
        name = controller.name
        return unless name && !name.empty?
        @controllers_by_name[name] = controller
      end

      def reset
        @controllers_by_name = {}
      end
    end
  end
end
