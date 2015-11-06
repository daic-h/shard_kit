module ShardingKit
  module Migration
    extend ActiveSupport::Concern

    included do
      class_attribute :shards
      class_attribute :shard_groups
      self.shards = []
      self.shard_groups = []

      alias_method_chain :announce, :sharding_kit
    end

    module ClassMethods
      def using(*args)
        self.shards += args
      end

      def using_group(*args)
        self.shard_groups += args
      end
    end

    def target_shards
      target = Set.new(shards)

      unless (groups = shard_groups.map(&:to_s)).empty?
        ActiveRecord::Base.shard_config.each do |name, spec|
          next unless Array.wrap(spec["group"]).any? {|g| groups.include?(g) }
          target << name.to_sym
        end
      end

      target.empty? ? [:master] : target.to_a
    end

    def announce_with_sharding_kit(message)
      announce_without_sharding_kit("#{message} - #{current_shard}")
    end

    def current_shard
      "Shard: #{ActiveRecord::Base.current_shard}"
    end
  end

  module MigrationProxy
    def target_shards
      migration.target_shards
    end
  end

  module Migrator
    extend ActiveSupport::Concern

    included do
      class << self
        alias_method_chain :up, :sharding_kit
        alias_method_chain :down, :sharding_kit
        alias_method_chain :run, :sharding_kit
        alias_method_chain :migrations, :sharding_kit
      end
    end

    module ClassMethods
      def up_with_sharding_kit(paths, version = nil)
        ActiveRecord::Base.shard_manager.using_all do
          begin
            up_without_sharding_kit(paths, version)
          rescue ActiveRecord::UnknownMigrationVersionError => e
            raise e unless migrations_without_sharding_kit(paths).any? {|m| m.version == version }
          end
        end
      end

      def down_with_sharding_kit(paths, version = nil)
        ActiveRecord::Base.shard_manager.using_all do
          begin
            down_without_sharding_kit(paths, version)
          rescue ActiveRecord::UnknownMigrationVersionError => e
            raise e unless migrations_without_sharding_kit(paths).any? {|m| m.version == version }
          end
        end
      end

      def run_with_sharding_kit(direction, paths, version)
        ActiveRecord::Base.shard_manager.using_all do
          begin
            run_without_sharding_kit(direction, paths, version)
          rescue ActiveRecord::UnknownMigrationVersionError => e
            raise e unless migrations_without_sharding_kit(paths).any? {|m| m.version == version }
          end
        end
      end

      def migrations_with_sharding_kit(paths)
        migrations = migrations_without_sharding_kit(paths)
        shard = ActiveRecord::Base.current_shard

        migrations.select {|m| m.target_shards.include?(shard) }
      end
    end
  end
end

ActiveRecord::Migration.send(:include, ShardingKit::Migration)
ActiveRecord::MigrationProxy.send(:include, ShardingKit::MigrationProxy)
ActiveRecord::Migrator.send(:include, ShardingKit::Migrator)
