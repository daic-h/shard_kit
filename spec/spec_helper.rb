require "rubygems"
require "bundler/setup"
require "pry"
require "rspec/its"
require "sharding_kit"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.profile_examples = 10

  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do |example|
    ShardingKitHelper.clean_all if example.metadata[:clean_all]
  end
end
