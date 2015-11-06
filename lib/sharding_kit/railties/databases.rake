require "active_record"
require "sharding_kit"

namespace :db do
  namespace :shard do
    desc "TODO"
    task create: "db:load_config" do
      ActiveRecord::Tasks::DatabaseTasks.create_current_shards
    end

    desc "TODO"
    task drop: "db:load_config" do
      ActiveRecord::Tasks::DatabaseTasks.drop_current_shards
    end
  end
end
