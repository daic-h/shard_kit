module ShardingKit
  class ShardManager
    DEFAULT_SHARD = :master

    def initialize
      @handlers = HashWithIndifferentAccess.new
    end

    def default_connection_handler=(handler)
      @handlers[DEFAULT_SHARD] = handler
    end

    def connection_handler_list
      @handlers.values.compact
    end

    def shard_name_of(handler)
      @handlers.key(handler).to_sym
    end

    def fetch_handler(shard)
      @handlers[shard] or raise "Nonexistent shard: #{shard}"
    end

    def using(shard, &block)
      switch_handler_to(fetch_handler(shard), &block)
    end

    def using_all(&block)
      connection_handler_list.each {|h| switch_handler_to(h, &block) }
    end

    def establish_connection(shard, spec)
      spec[:shard] = shard

      switch_handler_to(ActiveRecord::ConnectionAdapters::ConnectionHandler.new) do
        ActiveRecord::Base.establish_connection(spec)
        @handlers[shard] = ActiveRecord::Base.connection_handler
      end
    end

    private

    def switch_handler_to(handler, &block)
      prev_handler = ActiveRecord::RuntimeRegistry.connection_handler

      begin
        ActiveRecord::Base.connection_handler = handler
        block.call
      ensure
        ActiveRecord::Base.connection_handler = prev_handler
      end
    end
  end
end
