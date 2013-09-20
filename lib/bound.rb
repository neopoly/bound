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

    def method_missing(meth, *args, &blk)
      attribute = meth.to_s.gsub(/=$/, '')
      raise ArgumentError.new("Unknown attribute: #{attribute}")
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
