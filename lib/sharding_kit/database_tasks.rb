require "active_record/tasks/database_tasks"

module ShardingKit
  module DatabaseTasks
    def create_current_shards(environment = env)
      ShardingKit.configurations[environment].each_value do |spec|
        create(spec)
      end
    end

    def drop_current_shards(environment = env)
      ShardingKit.configurations[environment].each_value do |spec|
        drop(spec)
      end
    end
  end
end

ActiveRecord::Tasks::DatabaseTasks.extend(ShardingKit::DatabaseTasks)
