require "active_record/log_subscriber"

module ShardingKit
  module LogSubscriber
    def sql(event)
      @_shard = event.payload[:shard]
      super(event)
    end

    def debug(msg)
      conn = @_shard ? color("[Shard: #{@_shard}]", ActiveSupport::LogSubscriber::GREEN, true) : ""

      super(conn + msg)
    end
  end

  module AbstractAdapter
    class InstrumenterDecorator < ActiveSupport::ProxyObject
      def initialize(instrumenter, adapter)
        @instrumenter = instrumenter
        @adapter = adapter
      end

      def instrument(name, payload = {}, &block)
        payload[:shard] ||= @adapter.shard
        @instrumenter.instrument(name, payload, &block)
      end

      def method_missing(meth, *args, &block)
        @instrumenter.send(meth, *args, &block)
      end
    end

    def initialize(*)
      super
      @instrumenter = InstrumenterDecorator.new(@instrumenter, self)
    end

    def shard
      @config[:shard]
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ShardingKit::AbstractAdapter)
ActiveRecord::LogSubscriber.prepend(ShardingKit::LogSubscriber)
