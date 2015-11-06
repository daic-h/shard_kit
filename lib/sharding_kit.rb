require "active_record"
require "active_support/core_ext/class"

require "sharding_kit/log_subscriber"
require "sharding_kit/migration"
require "sharding_kit/model"
require "sharding_kit/proxy"
require "sharding_kit/railtie" if defined?(Rails)
require "sharding_kit/version"

module ShardingKit
end
