require "rubygems"
require "bundler/gem_tasks"

require "rspec/core"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList["spec/**/*_spec.rb"]
end

require "active_record"
require "sharding_kit"
require "sharding_kit/database_tasks"

namespace :sharding_kit do
  namespace :db do
    task :rails_env do
      unless defined? RAILS_ENV
        RAILS_ENV = ENV["RAILS_ENV"] ||= "test"
      end
    end

    task load_config: :rails_env do
      ActiveRecord::Base.configurations =
        YAML.load_file(File.join(File.dirname(__FILE__), "spec/config/database.yml"))
    end

    desc "create test database"
    task create: :load_config do
      ActiveRecord::Tasks::DatabaseTasks.create_current(RAILS_ENV)
      ActiveRecord::Tasks::DatabaseTasks.create_current_shards(RAILS_ENV)
    end

    desc "drop test database"
    task drop: :load_config do
      ActiveRecord::Tasks::DatabaseTasks.drop_current(RAILS_ENV)
      ActiveRecord::Tasks::DatabaseTasks.drop_current_shards(RAILS_ENV)
    end

    desc "migrate test tables"
    task migrate: :load_config do
      env = RAILS_ENV.to_sym

      ActiveRecord::Base.establish_connection(env)
      ShardingKit.establish_connections(env)

      ActiveRecord::Base.on_each_db do
        connection = ActiveRecord::Base.connection

        connection.create_table :users do |t|
          t.string :name
          t.timestamps null: true
        end

        unless ActiveRecord::Base.connection_name == :master
          connection.create_table :suppliers do |t|
            t.string :name
            t.timestamps null: false
          end

          connection.create_table :accounts do |t|
            t.belongs_to :supplier
            t.string :name
            t.timestamps null: false
          end

          connection.create_table :customers do |t|
            t.string :name
            t.timestamps null: false
          end

          connection.create_table :orders do |t|
            t.belongs_to :customer
            t.string :name
            t.timestamps null: false
          end
        end
      end
    end

    desc "reset test databases"
    task reset: ["sharding_kit:db:drop", "sharding_kit:db:create", "sharding_kit:db:migrate"]
  end
end
