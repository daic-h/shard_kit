require "active_record"
require "active_support/core_ext/class"

require "sharding_kit/log_subscriber"
require "sharding_kit/migration"
require "sharding_kit/model"
require "sharding_kit/proxy"
require "sharding_kit/railtie" if defined?(Rails)
require "sharding_kit/version"

module ShardingKit
  def self.configurations
    @config ||= begin
      conf = HashWithIndifferentAccess.new
      ActiveRecord::Base.configurations.each do |shard, spec|
        conf[shard] = spec["connections"] || {}
      end
      conf
    end
  end

  def self.establish_connections(env)
    configurations[env].each do |shard, spec|
      ActiveRecord::Base.connection_manager.establish_connection(shard, spec)
    end
  end
end
