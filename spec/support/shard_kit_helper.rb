require "active_support/core_ext/class/subclasses"

module ShardingKitHelper
  module_function

  def clean_all
    ActiveRecord::Base.subclasses.each do |subclass|
      connection_names.each do |name|
        begin
          subclass.on_db(name).delete_all
        rescue
          nil
        end
      end
    end
  end

  def connection_names
    ActiveRecord::Base.connection_config[:connections].keys + ["master"]
  end
end
