require "sharding_kit/connection_manager"

module ShardingKit
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :connection_manager, instance_writer: false

      self.connection_manager = ConnectionManager.new
      connection_manager.default_connection_handler = default_connection_handler

      after_initialize { on_db(connection_name) }
    end

    module ClassMethods
      def connection_name
        connection_manager.connection_name_for(connection_handler)
      end

      def on_db(conn_name, &block)
        if block_given?
          connection_manager.on_db(conn_name, &block)
        else
          Proxy.new(self, conn_name)
        end
      end

      def on_each_db(&block)
        connection_manager.on_each_db(&block)
      end

      %w(clear_cache! clear_active_connections! clear_reloadable_connections! clear_all_connections!).each do |method|
        class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{method}(*); on_each_db { super }; end
        CODE
      end
    end

    def connection_name
      @__connection_name || self.class.connection_name
    end

    def on_db(conn_name)
      @__connection_name = conn_name
      self
    end

    def association(*)
      Proxy.new(super, connection_name)
    end

    %w(with_transaction_returning_status reload touch).each do |method|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{method}(*); self.class.on_db(connection_name) { super }; end
      CODE
    end
  end
end

ActiveRecord::Base.send(:include, ShardingKit::Model)
