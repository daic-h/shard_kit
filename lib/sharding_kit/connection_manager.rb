module ShardingKit
  class ConnectionManager
    def initialize
      @handlers = HashWithIndifferentAccess.new
    end

    def default_connection_handler=(handler)
      @handlers[:master] = handler
    end

    def connection_name_for(handler)
      @handlers.key(handler).to_sym
    end

    def fetch_handler(conn_name)
      @handlers[conn_name] or raise "Nonexistent connection: #{conn_name}"
    end

    def on_db(conn_name, &block)
      switch_handler_to(fetch_handler(conn_name), &block)
    end

    def on_each_db(&block)
      connection_handler_list.each {|h| switch_handler_to(h, &block) }
    end

    def establish_connection(conn_name, spec)
      spec[:connection_name] = conn_name

      switch_handler_to(ActiveRecord::ConnectionAdapters::ConnectionHandler.new) do
        ActiveRecord::Base.establish_connection(spec)
        @handlers[conn_name] = ActiveRecord::Base.connection_handler
      end
    end

    private

    def connection_handler_list
      @handlers.values.compact
    end

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
