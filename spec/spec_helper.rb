if ENV['coverage']
  require 'simplecov'
  SimpleCov.start
end

require 'minitest/autorun'
require 'minitest/spec'

require 'support/hash_object'

require 'bound'
