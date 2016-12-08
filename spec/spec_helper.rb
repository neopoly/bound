if ENV['COVERAGE'] || ENV['CODECLIMATE_REPO_TOKEN']
  require 'simplecov'
  SimpleCov.start
end

require 'minitest/autorun'
require 'minitest/spec'

require 'support/hash_object'

require 'bound'
