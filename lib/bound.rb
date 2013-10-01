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

  def self.required(*args)
    bound = new_bound_class

    if args.last.kind_of? Hash
      bound.nested(args.pop)
    end

    bound.set_attributes(*args)
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
        object.send @name
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
        "#{@name}=#{@value.inspect}"
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

      def set_attributes(*attributes)
        if attributes.any? { |a| !a.kind_of? Symbol }
          raise ArgumentError.new("Invalid list of attributes: #{attributes.inspect}")
        end

        attributes.each do |attribute|
          self.attrs[attribute] = RequiredAttribute
        end

        define_attribute_accessors attributes

        self
      end

      def optional(*optionals)
        if optionals.any? { |a| !a.kind_of? Symbol }
          raise ArgumentError.new("Invalid list of optional attributes: #{optionals.inspect}")
        end

        optionals.each do |attribute|
          self.attrs[attribute] = Attribute
        end

        define_attribute_accessors optionals

        self
      end

      def nested(nested_attributes)
        attributes = nested_attributes.keys

        attributes.each do |attribute|
          self.attrs[attribute]               = RequiredAttribute
          self.nested_attr_classes[attribute] = nested_attributes[attribute]
        end

        define_attribute_accessors attributes

        self
      end

      alias :build :new

      private

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

    def initialize(hash_or_object = {})
      seed hash_or_object
      validate!
    end


    def method_missing(meth, *args, &blk)
      attribute = meth.to_s.gsub(/=$/, '')
      raise ArgumentError.new("Unknown attribute: #{attribute}")
    end

    def get_attributes
      self.class.attrs.keys.map do |attribute_name|
        get_attribute(attribute_name)
      end
    end

    def __attributes__
      puts "BoundClass#__attributes__ is deprecated: use get_attributes"
      get_attributes.map(&:name)
    end

    private

    def get_attribute(attribute_name)
      attribute_class = self.class.attrs[attribute_name]
      nested_class = self.class.nested_attr_classes[attribute_name]

      var = :"@#{attribute_name}"
      attribute = instance_variable_get(var)

      unless attribute
        attribute = instance_variable_set(var, attribute_class.new(attribute_name))
        attribute.nested_class = nested_class if nested_class
      end

      attribute
    end

    def validate!
      get_attributes.each do |attribute|
        raise ArgumentError.new("Missing attribute: #{attribute.name}") unless attribute.valid?
      end
    end

    def seed(hash_or_object)
      case hash_or_object
      when Hash
        seeder = HashSeeder.new(self)
      else
        seeder = ObjectSeeder.new(self)
      end

      seeder.seed(hash_or_object)
    end
  end

  class HashSeeder
    def initialize(receiver)
      @receiver = receiver
    end

    def seed(hash)
      hash.each do |key, value|
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
        begin
          value = attribute.call_on(object)
        rescue NoMethodError => e
          value = nil
          raise ArgumentError, "missing #{attribute.name}" if attribute.required?
        end

        method = "#{attribute.name}="
        if @receiver.respond_to?(method)
          @receiver.send method, value
        else
          raise NoMethodError, "undefined method `#{method}' for #{self}"
        end
      end
    end
  end
end
