require "sharding_kit/shard_manager"

module ShardingKit
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :shard_manager, instance_writer: false

      self.shard_manager = ShardManager.new
      shard_manager.default_connection_handler = default_connection_handler

      after_initialize :set_current_shard
    end

    module ClassMethods
      def shard_configurations
        conf = HashWithIndifferentAccess.new
        configurations.each do |shard, spec|
          conf[shard] = spec["connections"] || {}
        end
        conf
      end

      def shard_config
        using(ShardManager::DEFAULT_SHARD).connection_config[:connections]
      end

      def current_shard
        shard_manager.shard_name_of(connection_handler)
      end

      def using(shard, &block)
        if block_given?
          shard_manager.using(shard, &block)
        else
          Proxy.new(self, shard)
        end
      end

      def default_shard(shard)
        handler = shard_manager.fetch_handler(shard)

        define_singleton_method(:default_connection_handler) do
          handler
        end
      end

      def establish_shard_connections(env)
        shard_configurations[env].each do |shard, spec|
          shard_manager.establish_connection(shard, spec)
        end
      end

      def clear_cache!
        shard_manager.using_all do
          connection.schema_cache.clear!
        end
      end

      def clear_active_connections!
        shard_manager.using_all do
          connection_handler.clear_active_connections!
        end
      end

      def clear_reloadable_connections!
        shard_manager.using_all do
          connection_handler.clear_reloadable_connections!
        end
      end

      def clear_all_connections!
        shard_manager.using_all do
          connection_handler.clear_all_connections!
        end
      end
    end

    def current_shard
      @_current_shard || self.class.current_shard
    end

    def using(shard)
      tap { @_current_shard = shard }
    end

    def association(*)
      Proxy.new(super, current_shard)
    end

    def with_transaction_returning_status(*)
      self.class.using(current_shard) { super }
    end

    def reload(*)
      self.class.using(current_shard) { super }
    end

    def touch(*)
      self.class.using(current_shard) { super }
    end

    private

    def set_current_shard
      using(current_shard)
    end
  end
end

ActiveRecord::Base.send(:include, ShardingKit::Model)
