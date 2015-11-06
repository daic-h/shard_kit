module ShardingKit
  class Proxy < ActiveSupport::ProxyObject
    def initialize(object, shard)
      @object = object
      @shard = shard
    end

    def using(shard)
      @shard = shard
      self
    end

    def method_missing(action, *args, &block)
      result = ::ActiveRecord::Base.using(@shard) do
        @object.send(action, *args, &block)
      end

      if result.is_a?(::ActiveRecord::Relation)
        result, @object = self, result
      end

      result
    end
  end
end
