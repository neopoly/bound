require "bound/version"
require "bound/caller"

class Bound
  def self.new(*args)
    new_bound_class.required(*args)
  end

  def self.optional(*args)
    new_bound_class.optional(*args)
  end

  def self.required(*args)
    new_bound_class.required(*args)
  end

  private

  def self.new_bound_class
    Class.new(BoundClass) do
      initialize_values
    end
  end

  class BoundClass
    class Attribute
      attr_reader :name, :value
      attr_accessor :nested_class

      def initialize(name)
        @name = name
      end

      def assign(value)
        @assigned = true
        if nested_class
          @value = assign_nested(value)
        else
          @value = value
        end
      end

      def assign_nested(value)
        nested_attribute = NestedAttribute.new(nested_class)
        nested_attribute.resolve(value)
      end

      def call_on(object)
        Caller.call(object, @name)
      end

      def valid?
        !required? || is_assigned?
      end

      def required?
        false
      end

      def is_assigned?
        !!@assigned
      end

      def inspect
        @value.inspect
      end
    end

    class RequiredAttribute < Attribute
      def required?; true; end
    end

    class NestedAttribute
      def initialize(bound_definition)
        if bound_definition.kind_of?(Array)
          @assigner = ArrayAssigner.new(bound_definition)
        else
          @assigner = ValueAssigner.new(bound_definition)
        end
      end

      def resolve(bound_arguments)
        @assigner.resolve(bound_arguments)
      end

      class ArrayAssigner
        def initialize(definitions)
          @bound_class = definitions.first
        end

        def resolve(arguments_list)
          raise ArgumentError.new("Expected #{arguments_list.inspect} to be an array") unless arguments_list.kind_of? Array
          arguments_list.map do |arguments|
            @bound_class.new(arguments)
          end
        end
      end

      class ValueAssigner
        def initialize(definition)
          @bound_class = definition
        end

        def resolve(arguments)
          @bound_class.new(arguments)
        end
      end
    end


    class << self
      attr_accessor :attrs, :nested_attr_classes

      def initialize_values
        self.attrs = {}
        self.nested_attr_classes = {}
      end

      def optional(*attributes)
        if attributes.last.kind_of? Hash
          nested_attributes = attributes.pop
        else
          nested_attributes = {}
        end

        set_attributes :optional, attributes, nested_attributes

        self
      end

      def required(*attributes)
        if attributes.last.kind_of? Hash
          nested_attributes = attributes.pop
        else
          nested_attributes = {}
        end

        set_attributes :required, attributes, nested_attributes

        self
      end

      private

      def set_attributes(flag, attributes, nested_attributes = {})
        is_optional = flag == :optional

        if attributes.any? { |a| !a.kind_of? Symbol }
          raise ArgumentError.new("Invalid list of attributes: #{attributes.inspect}")
        end

        attributes.each do |attribute|
          if is_optional
            self.attrs[attribute] = Attribute
          else
            self.attrs[attribute] = RequiredAttribute
          end
        end

        define_attribute_accessors attributes

        if nested_attributes.any?
          set_attributes flag, nested_attributes.keys
          nested_attributes.each do |attribute_name, attribute_class|
            self.nested_attr_classes[attribute_name] = attribute_class
          end
        end
      end

      def define_attribute_accessors(attributes)
        define_attribute_readers attributes
        define_attribute_writers attributes
      end

      def define_attribute_readers(attributes)
        attributes.each do |attribute|
          define_method attribute do
            get_attribute(attribute).value
          end
        end
      end

      def define_attribute_writers(attributes)
        attributes.each do |attribute|
          define_method :"#{attribute}=" do |value|
            get_attribute(attribute).assign value
          end
        end
      end
    end

    def initialize(*seeds)
      @attributes = {}
      seeds.reverse.each do |seed|
        seed_with seed
      end
      validate!
    end


    def method_missing(meth, *args, &blk)
      attribute = meth.to_s.gsub(/=$/, '')
      raise ArgumentError.new("Unknown attribute: #{self.class}##{attribute}")
    end

    def get_attributes
      self.class.attrs.keys.map do |attribute_name|
        get_attribute(attribute_name)
      end
    end

    def has_attribute?(attr)
      self.class.attrs.keys.include? attr
    end

    def __attributes__
      puts "BoundClass#__attributes__ is deprecated: use get_attributes"
      get_attributes.map(&:name)
    end

    def get_attribute(attribute_name)
      attribute_class = self.class.attrs[attribute_name]
      nested_class = self.class.nested_attr_classes[attribute_name]

      return nil if attribute_class.nil?

      attribute = @attributes[attribute_name]

      unless attribute
        @attributes[attribute_name] = attribute_class.new(attribute_name)
        attribute = @attributes[attribute_name]
        attribute.nested_class = nested_class if nested_class
      end

      attribute
    end

    def ==(other)
      return false unless other

      get_attributes.all? do |attribute|
        attribute.value == Caller.call(other, attribute.name)
      end
    end

    private

    def validate!
      get_attributes.each do |attribute|
        raise ArgumentError.new("Missing attribute: #{self.class}##{attribute.name}") unless attribute.valid?
      end
    end

    def seed_with(seed)
      case seed
      when Hash
        seeder = HashSeeder.new(self)
      else
        seeder = ObjectSeeder.new(self)
      end

      seeder.seed(seed)
    end
  end

  class HashSeeder
    def initialize(receiver)
      @receiver = receiver
    end

    def seed(hash)
      hash.each do |key, value|
        attribute = @receiver.get_attribute(key)
        next if attribute && attribute.is_assigned?

        method = "#{key}="
        @receiver.send method, value
      end
    end
  end

  class ObjectSeeder
    def initialize(receiver)
      @receiver = receiver
    end

    def seed(object)
      @receiver.get_attributes.each do |attribute|
        next if attribute.is_assigned?

        begin
          value = attribute.call_on(object)
          assign_to_receiver attribute, value
        rescue NoMethodError
        end
      end
    end

    private
    def assign_to_receiver(attribute, value)
      method = "#{attribute.name}="
      @receiver.send(method, value)
    end

  end
end
