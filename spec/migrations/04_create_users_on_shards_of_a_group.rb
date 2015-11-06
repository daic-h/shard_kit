class CreateUsersOnShardsOfAGroup < ActiveRecord::Migration
  using_group(:group_1)

  def self.up
    User.create!(name: "Group")
  end

  def self.down
    User.delete_all
  end
end
