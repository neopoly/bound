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
    build_class(hash.keys).new(hash)
  end

  def self.build_class(attributes)
    Class.new do
      attr_accessor(*attributes)

      def initialize(hash)
        hash.each do |attr, value|
          public_send "#{attr}=", value
        end
      end
    end
  end
end
