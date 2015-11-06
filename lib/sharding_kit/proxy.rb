module ShardingKit
  class Proxy < ActiveSupport::ProxyObject
    def initialize(object, connection_name)
      @object = object
      @connection_name = connection_name
    end

    def on_db(connection_name)
      @connection_name = connection_name
      self
    end

    def method_missing(action, *args, &block)
      result = ::ActiveRecord::Base.on_db(@connection_name) do
        @object.__send__(action, *args, &block)
      end

      if result.is_a?(::ActiveRecord::Relation)
        result, @object = self, result
      end

      result
    end
  end
end
