require 'minitest/autorun'
require 'minitest/spec'

require 'bound'

# HashObject behaves like an OpenStruct
# but there is no method_missing involved.
#
# Missing keys in the source hash result in
# NoMethodErrors on a later call
#
# OpenStruct.new(:id => 2).name # => nil
# HashObject.new(:id => 2).name # => NoMethodError
#
class HashObject
  def self.new(hash)
    attributes  = hash.keys
    values      = hash.values
    if attributes.empty?
      Class.new
    else
      Struct.new(*attributes).new(*values)
    end
  end
end
