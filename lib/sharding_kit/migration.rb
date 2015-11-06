module ShardingKit
  module Migration
    extend ActiveSupport::Concern

    included do
      class_attribute :connections
      class_attribute :connection_groups
      self.connections = []
      self.connection_groups = []

      alias_method_chain :announce, :connection
    end

    module ClassMethods
      def using(*args)
        self.connections += args
      end

      def using_group(*args)
        self.connection_groups += args
      end
    end

    def target_connections
      target = Set.new(connections)
      unless (groups = connection_groups.map(&:to_s)).empty?
        config = ActiveRecord::Base.on_db(:master).connection_config
        config[:connections].each do |name, spec|
          next unless Array.wrap(spec["group"]).any? {|g| groups.include?(g) }
          target << name.to_sym
        end
      end
      target.empty? ? [:master] : target.to_a
    end

    def announce_with_connection(message)
      announce_without_connection("#{message} - #{connection_name}")
    end

    def connection_name
      "Connection: #{ActiveRecord::Base.connection_name}"
    end
  end

  module MigrationProxy
    def target_connections
      migration.target_connections
    end
  end

  module Migrator
    extend ActiveSupport::Concern

    included do
      class << self
        alias_method_chain :up, :connection
        alias_method_chain :down, :connection
        alias_method_chain :run, :connection
        alias_method_chain :migrations, :connection
      end
    end

    module ClassMethods
      def up_with_connection(paths, version = nil)
        ActiveRecord::Base.on_each_db do
          begin
            up_without_connection(paths, version)
          rescue ActiveRecord::UnknownMigrationVersionError => e
            raise e unless migrations_without_connection(paths).any? {|m| m.version == version }
          end
        end
      end

      def down_with_connection(paths, version = nil)
        ActiveRecord::Base.on_each_db do
          begin
            down_without_connection(paths, version)
          rescue ActiveRecord::UnknownMigrationVersionError => e
            raise e unless migrations_without_connection(paths).any? {|m| m.version == version }
          end
        end
      end

      def run_with_connection(direction, paths, version)
        ActiveRecord::Base.on_each_db do
          begin
            run_without_connection(direction, paths, version)
          rescue ActiveRecord::UnknownMigrationVersionError => e
            raise e unless migrations_without_connection(paths).any? {|m| m.version == version }
          end
        end
      end

      def migrations_with_connection(paths)
        migrations = migrations_without_connection(paths)
        conn_name = ActiveRecord::Base.connection_name

        migrations.select {|m| m.target_connections.include?(conn_name) }
      end
    end
  end
end

ActiveRecord::Migration.send(:include, ShardingKit::Migration)
ActiveRecord::MigrationProxy.send(:include, ShardingKit::MigrationProxy)
ActiveRecord::Migrator.send(:include, ShardingKit::Migrator)
