class CreateUsersOnShard1 < ActiveRecord::Migration
  using(:shard_1)

  def self.up
    User.create!(name: "Shard1")
  end

  def self.down
    User.delete_all
  end
end
