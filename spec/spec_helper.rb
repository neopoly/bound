if ENV['CODECLIMATE_REPO_TOKEN']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

if ENV['coverage']
  require 'simplecov'
  SimpleCov.start
end

require 'minitest/autorun'
require 'minitest/spec'

require 'support/hash_object'

require 'bound'
