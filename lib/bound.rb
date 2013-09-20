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
      attr_accessor :attributes, :optionals

      def set_attributes(*attributes)
        attributes = attributes.dup

        optionals = extract_optionals(attributes)

        self.optionals = optionals
        attr_accessor(*optionals)

        self.attributes = attributes
        attr_accessor(*attributes)
      end

      def extract_optionals(attributes)
        if attributes.last.kind_of? Hash
          attributes.pop[:optional]
        else
          []
        end
      end
    end

    def initialize(hash_or_object)
      build_hash(hash_or_object)
      validate!
      seed
    end

    private

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
        insert_attributes_into_hash(hash_or_object)
        insert_optionals_into_hash(hash_or_object)
      end
    end

    def insert_attributes_into_hash(object)
      self.class.attributes.inject(@hash) do |h, attr|
        begin
          h[attr] = object.public_send(attr)
        rescue NoMethodError
          raise ArgumentError.new("Missing attribute: #{attr}")
        end
        h
      end
    end

    def insert_optionals_into_hash(object)
      self.class.optionals.inject(@hash) do |h, attr|
        begin
          h[attr] = object.public_send(attr)
        rescue NoMethodError
        end
        h
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
