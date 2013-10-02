# HashObject behaves like an OpenStruct
# but there is no method_missing involved.
#
# Missing keys in the source hash result in
# NoMethodErrors on a later call
#
# OpenStruct.new(:id => 2).name # => nil
# HashObject.new(:id => 2).name # => NoMethodError
#
# We also can not us struct, because it breaks on 1.9.3
# with ?-postifxed attributes. 
#
# Hence this bare-metal implementation
#
class HashObject
  def self.new(hash)
    attributes  = hash.keys

    cls = Class.new

    attributes.each do |attr|
      define_accessor cls, attr
    end

    instance = cls.new

    attributes.each do |attr| 
      value = map_value(hash[attr])
      assign_value instance, attr, value
    end

    instance
  end

  def self.map_value(value)
    case value
    when Hash
      HashObject.new(value)
    when Array
      value.map { |v| map_value(v) }
    else
      value
    end
  end

  def self.define_accessor(cls, attribute)
    cls.send :define_method, :"#{attribute}=" do |a|
      @suffix_attributes ||= {}
      @suffix_attributes[attribute] = a
    end

    cls.send :define_method, :"#{attribute}" do
      @suffix_attributes ||= {}
      @suffix_attributes[attribute]
    end
  end

  def self.assign_value(instance, attr, value)
    instance.send :"#{attr}=", value
  end
end
