class CreateUsersOnMultiplesGroups < ActiveRecord::Migration
  using_group(:group_1, :group_2)

  def self.up
    User.create!(name: "MultipleGroup")
  end

  def self.down
    User.delete_all
  end
end
