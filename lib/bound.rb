require "bound/version"

class Bound
  def self.new(*args)
    new_bound_class.set_attributes(*args)
  end

  def self.nested(*args)
    new_bound_class.nested(*args)
  end

  def self.optional(*args)
    new_bound_class.optional(*args)
  end

  private

  def self.new_bound_class
    Class.new(BoundClass) do
      initialize_values
    end
  end

  class BoundClass
    class Attribute
      attr_reader :value

      def initialize(name)
        @name = name
      end

      def assign(value)
        @value = value
      end

      def optional?
        true
      end
    end

    class RequiredAttribute < Attribute
      def optional?; false; end
    end



    class << self
      attr_accessor :attributes, :optional_attributes, :nested_attributes

      def initialize_values
        self.attributes = []
        self.optional_attributes = []
        self.nested_attributes = []
      end

      def set_attributes(*attributes)
        if attributes.any? { |a| !a.kind_of? Symbol }
          raise ArgumentError.new("Invalid list of attributes: #{attributes.inspect}")
        end

        self.attributes += attributes
        attributes.each do |attribute|
          define_method attribute do
            get_attribute(RequiredAttribute, attribute).value
          end

          define_method :"#{attribute}=" do |value|
            get_attribute(RequiredAttribute, attribute).assign value
          end
        end

        self
      end

      def optional(*optionals)
        if optionals.any? { |a| !a.kind_of? Symbol }
          raise ArgumentError.new("Invalid list of optional attributes: #{optionals.inspect}")
        end

        self.optional_attributes += optionals
        optionals.each do |attribute|
          define_method attribute do
            get_attribute(Attribute, attribute).value
          end

          define_method :"#{attribute}=" do |value|
            get_attribute(Attribute, attribute).assign value
          end
        end

        self
      end

      def nested(nested_attributes)
        attributes = nested_attributes.keys
        self.nested_attributes += attributes
        self.attributes += attributes

        attributes.each do |attribute|
          define_method attribute do
            get_attribute(RequiredAttribute, attribute).value
          end

          define_method :"#{attribute}=" do |value|
            nested_target = nested_attributes[attribute]
            value = extract_values_for_nested_attribute(nested_target, value)

            get_attribute(RequiredAttribute, attribute).assign value
          end
        end

        self
      end

      alias :build :new
    end

    def initialize(hash_or_object = {})
      hash = build_hash(hash_or_object)
      validate!(hash)
      seed(hash)
    end

    def __attributes__
      self.class.attributes + self.class.optional_attributes
    end

    def method_missing(meth, *args, &blk)
      attribute = meth.to_s.gsub(/=$/, '')
      raise ArgumentError.new("Unknown attribute: #{attribute}")
    end

    def inspect
      class_name = self.class.name
      id = '%0#16x' % (object_id << 1)
      values = (self.class.attributes + self.class.optional_attributes).map do |attr|
        "#{attr}=#{public_send(attr).inspect}"
      end

      (["#<#{class_name}:#{id}"] + values + [">"]).join(" ")
    end

    private

    def get_attribute(attribute_class, attribute_name)
      var = :"@#{attribute_name}"
      attribute = instance_variable_get(var)

      unless attribute
        attribute = instance_variable_set(var, attribute_class.new(attribute_name))
      end

      attribute
    end

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

    def validate!(hash)
      self.class.attributes.each do |attribute|
        raise ArgumentError.new("Missing attribute: #{attribute}") unless hash.key?(attribute)
      end
    end

    def seed(hash)
      HashSeeder.new(self).seed(hash)
    end

    def build_hash(hash_or_object)
      case hash_or_object
      when Hash
        hash = hash_or_object
      else
        hash = {}
        insert_into_hash(hash, self.class.attributes, hash_or_object)
        insert_into_hash(hash, self.class.optional_attributes, hash_or_object)
      end

      hash
    end

    def insert_into_hash(hash, attributes, object)
      attributes.each_with_object(hash) do |attr, h|
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
