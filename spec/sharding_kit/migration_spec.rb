require "spec_helper"

RSpec.describe ShardingKit::Migration do
  describe "#target_shards" do
    subject { migration_class.new.target_shards }

    context "with using definitions" do
      let(:migration_class) do
        Class.new(ActiveRecord::Migration) { using(:shard_1) }
      end

      it { is_expected.to eq([:shard_1]) }
    end

    context "With using_group definitions" do
      let(:migration_class) do
        Class.new(ActiveRecord::Migration) { using_group(:group_1) }
      end

      it { is_expected.to eq([:shard_1, :shard_2]) }
    end
  end

  describe "migrations" do
    around(:each) do |example|
      migrations_root = File.expand_path(File.join(File.dirname(__FILE__), "..", "migrations"))
      begin
        ActiveRecord::Migrator.run(:up, migrations_root, example.metadata[:version])
        example.run
      ensure
        ActiveRecord::Migrator.run(:down, migrations_root, example.metadata[:version])
      end
    end

    it "should run just in the master shard", version: 1 do
      expect(User.using(:master).where(name: "Master").take).to_not be_nil
      expect(User.using(:shard_1).where(name: "Master").take).to be_nil
    end

    it "should run on specific shard", version: 2 do
      expect(User.using(:master).where(name: "Shard1").take).to be_nil
      expect(User.using(:shard_1).where(name: "Shard1").take).to_not be_nil
      expect(User.using(:shard_2).where(name: "Shard1").take).to be_nil
    end

    it "should run on specifieds shards", version: 3 do
      expect(User.using(:master).where(name: "Both").take).to be_nil
      expect(User.using(:shard_1).where(name: "Both").take).to_not be_nil
      expect(User.using(:shard_2).where(name: "Both").take).to_not be_nil
      expect(User.using(:shard_3).where(name: "Both").take).to be_nil
    end

    it "should run on specified group", version: 4 do
      expect(User.using(:master).where(name: "Group").take).to be_nil
      expect(User.using(:shard_1).where(name: "Group").take).to_not be_nil
      expect(User.using(:shard_2).where(name: "Group").take).to_not be_nil
      expect(User.using(:shard_3).where(name: "Group").take).to be_nil
      expect(User.using(:shard_4).where(name: "Group").take).to be_nil
      expect(User.using(:shard_5).where(name: "Group").take).to be_nil
      expect(User.using(:shard_6).where(name: "Group").take).to be_nil
    end

    it "should run once per shard", version: 5 do
      expect(User.using(:master).where(name: "MultipleGroup").take).to be_nil
      expect(User.using(:shard_1).where(name: "MultipleGroup").take).to_not be_nil
      expect(User.using(:shard_2).where(name: "MultipleGroup").take).to_not be_nil
      expect(User.using(:shard_3).where(name: "MultipleGroup").take).to_not be_nil
      expect(User.using(:shard_4).where(name: "MultipleGroup").take).to_not be_nil
      expect(User.using(:shard_5).where(name: "MultipleGroup").take).to be_nil
      expect(User.using(:shard_6).where(name: "MultipleGroup").take).to be_nil
    end
  end
end
