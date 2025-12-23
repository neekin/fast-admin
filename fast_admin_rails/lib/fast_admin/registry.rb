module FastAdmin
  class Registry
    @controllers = {}

    class << self
      def register(controller_class)
        key = controller_class.name
        @controllers[key] = controller_class if key
      end

      def controllers
        @controllers.values
      end

      def reset!
        @controllers = {}
      end
    end
  end
end
