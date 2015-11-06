module ShardingKit
  module Sharding
    def default_shard(shard)
      handler = connection_manager.fetch_handler(shard)

      define_singleton_method(:default_connection_handler) do
        handler
      end
    end

    def establish_shard_connections(env)
      shard_configurations[env].each do |shard, spec|
        connection_manager.establish_connection(shard, spec)
      end
    end

    def shard_configurations # TODO
      conf = HashWithIndifferentAccess.new
      configurations.each do |shard, spec|
        conf[shard] = spec["connections"] || {}
      end
      conf
    end

    def shard_config # TODO
      connection_manager.on_default_db.connection_config[:connections]
    end
  end
end
