class CreateUsersOnBothShards < ActiveRecord::Migration
  using(:shard_1, :shard_2)

  def self.up
    User.create!(name: "Both")
  end

  def self.down
    User.delete_all
  end
end
