require "rails/railtie"

module ShardingKit
  class Railtie < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), "railties/*.rake")].each { |ext| load ext }

      require "sharding_kit/database_tasks"
    end

    initializer "sharding_kit.initialize_database" do
      ShardingKit.establish_connections(Rails.env)
    end
  end
end
