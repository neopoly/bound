require "bound/version"

class Bound
  def self.new(*args)
    new_bound_class(*args)
  end

  private

  def self.new_bound_class(*attributes)
    Class.new(BoundClass) do
      set_attributes(*attributes)
    end
  end

  class BoundClass
    class << self
      attr_accessor :attributes, :optionals, :nested

      def set_attributes(*attributes)
        self.attributes = attributes
        attr_accessor *attributes

        self.optionals  = []
        self.nested     = []
      end

      def optional(*optionals)
        self.optionals = optionals
        attr_accessor *optionals

        self
      end

      def nested(nested_attributes)
        attributes = nested_attributes.keys
        self.nested = attributes
        self.attributes += attributes
        attr_reader *attributes
        
        attributes.each do |attribute|
          define_method :"#{attribute}=" do |initial_values|
            nested_target = nested_attributes[attribute]
            value = extract_values_for_nested_attribute(nested_target, initial_values)

            instance_variable_set :"@#{attribute}", value
          end
        end

        self
      end

      alias :build :new
    end

    def initialize(hash_or_object = {})
      build_hash(hash_or_object)
      validate!
      seed
    end

    def method_missing(meth, *args, &blk)
      attribute = meth.to_s.gsub(/=$/, '')
      raise ArgumentError.new("Unknown attribute: #{attribute}")
    end

    def inspect
      class_name = self.class.name
      id = '%0#16x' % (object_id << 1)
      values = (self.class.attributes + self.class.optionals).map do |attr|
        "#{attr}=#{public_send(attr).inspect}"
      end

      (["#<#{class_name}:#{id}"] + values + [">"]).join(" ")
    end

    private

    def build_nested_value(bound_class, init)
      bound_class.new(init)
    end

    def extract_values_for_nested_attribute(nested_target, initial_values)
      if nested_target.kind_of? Array
        raise ArgumentError.new("Expected #{initial_values.inspect} to be an array") unless initial_values.kind_of? Array

        initial_values.map do |initial_value|
          build_nested_value(nested_target.first, initial_value)
        end
      else
        build_nested_value(nested_target, initial_values)
      end
    end

    def validate!
      self.class.attributes.each do |attribute|
        raise ArgumentError.new("Missing attribute: #{attribute}") unless @hash.key?(attribute)
      end
    end

    def seed
      HashSeeder.new(self).seed(@hash)
    end

    def build_hash(hash_or_object)
      case hash_or_object
      when Hash
        @hash = hash_or_object
      else
        @hash = {}
        insert_into_hash(self.class.attributes, hash_or_object)
        insert_into_hash(self.class.optionals, hash_or_object)
      end
    end

    def insert_into_hash(attributes, object)
      attributes.each_with_object(@hash) do |attr, h|
        begin
          h[attr] = object.public_send(attr)
        rescue NoMethodError
        end
      end
    end
  end

  class HashSeeder
    def initialize(receiver)
      @receiver = receiver
    end

    def seed(hash)
      hash.each do |key, value|
        @receiver.public_send "#{key}=", value
      end
    end
  end
end
