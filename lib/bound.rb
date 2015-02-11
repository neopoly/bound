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

  def self.validate?
    !@validation_disabled
  end

  def self.disable_validation
    @validation_disabled = true
    StaticBoundClass.define_initializer_without_validation
  end

  private

  def self.new_bound_class
    Class.new(StaticBoundClass) do
    end
  end

  class BoundValidator
    attr_accessor :attributes, :optional_attributes, :nested_array_attributes

    def initialize(bound, target, overwrite)
      @bound = bound
      @target = target
      @overwrite = overwrite
    end

    def validate!
      ensure_all_given_attributes_are_known!
      attributes.each do |attribute|
        ensure_present! attribute
      end
      nested_array_attributes.each do |nested_array_attribute|
        ensure_array! nested_array_attribute
      end
      ensure_all_attributes_are_callable!
    end

    private

    def ensure_all_given_attributes_are_known!
      (overwritten_attrs + target_attrs).each do |attr|
        unless (attributes + optional_attributes).include? attr
          a = (attributes + optional_attributes).inspect
          message = "Unknown attribute: #{attr.inspect} in #{a}"
          raise ArgumentError, message
        end
      end
    end

    def ensure_present!(attribute)
      if !overwritten?(attribute) && !target_has?(attribute)
        message = "Missing attribute: #{attribute}"
        raise ArgumentError, message
      end
    end

    def ensure_array!(attribute)
      message = "Expected %s to be an array"
      if overwritten?(attribute)
        unless val = overwritten(attribute).kind_of?(Array)
          raise(ArgumentError, message % val.inspect)
        end
      elsif target_has?(attribute)
        unless val = target(attribute).kind_of?(Array)
          raise(ArgumentError, message % val.inspect)
        end
      else
      end
    end

    def ensure_all_attributes_are_callable!
      attributes.each do |attr|
        @bound.send attr
      end
      optional_attributes.each do |attr|
        @bound.send attr if set? attr
      end
    end


    def overwritten_attrs
      if @overwrite
        @overwrite.keys
      else
        []
      end
    end

    def target_attrs
      if @target && @target.kind_of?(Hash)
        @target.keys
      else
        []
      end
    end

    def overwritten?(attr)
      @overwrite && @overwrite.key?(attr)
    end

    def overwritten(attr)
      @overwrite && @overwrite[attr]
    end

    def target_has?(attr)
      @target &&
        @target.kind_of?(Hash)?@target.key?(attr):@target.respond_to?(attr)
    end

    def target(attr)
      @target &&
        @target.kind_of?(Hash)?@target[attr]:@target.send(attr)
    end

    def set?(attr)
      target_has?(attr) || overwritten?(attr)
    end
  end

  class StaticBoundClass
    def ==(other)
      false unless other
      true
    end

    def validate!
    end

    def self.define_initializer_without_validation
      define_initializer(nil)
    end

    def self.define_initializer(after_init = 'validate!')
      code = <<-EOR
        def initialize(target = nil, overwrite = nil)
          @t, @o = target, overwrite
          %s
        end
      EOR

      class_eval code % after_init
    end

    def self.define_attributes(*attributes)
      if attributes.last.kind_of? Hash
        nested_attributes = attributes.pop
      else
        nested_attributes = {}
      end

      if nested_attributes.keys.any? { |a| !a.kind_of? Symbol }
        message = "Invalid list of attributes: #{nested_attributes.inspect}"
        raise ArgumentError, message
      end

      if attributes.any? { |a| !a.kind_of? Symbol }
        message = "Invalid list of attributes: #{attributes.inspect}"
        raise ArgumentError, message
      end

      nested_attributes.each do |attribute, nested_class|
        define_nested_delegate attribute, nested_class
        define_equality attribute
      end

      attributes.each do |attribute|
        define_delegate attribute
        define_equality attribute
      end
    end

    def self.define_validator
      attributes = symbolize_attributes(@attributes)
      optional_attributes = symbolize_attributes(@optional_attributes)
      nested_array_attributes = symbolize_attributes(@nested_array_attributes)

      code = <<-EOR
        def validate!
          v = Bound::BoundValidator.new(self, @t, @o)
          v.attributes = [#{attributes}]
          v.optional_attributes = [#{optional_attributes}]
          v.nested_array_attributes = [#{nested_array_attributes}]
          v.validate!
        end
        private :validate!
      EOR
      class_eval code
    end

    def self.symbolize_attributes(attributes)
      (attributes || []).map { |attr| ":#{attr}" }.join(", ")
    end

    def self.set_required_attributes(attributes, nested_array_attributes)
      @attributes ||= []
      @attributes += attributes
      @attributes += nested_array_attributes
      @nested_array_attributes ||= []
      @nested_array_attributes += nested_array_attributes
      define_validator
    end

    def self.set_optional_attributes(attributes, nested_array_attributes)
      @optional_attributes ||= []
      @optional_attributes += attributes
      @optional_attributes += nested_array_attributes
      @nested_array_attributes ||= []
      @nested_array_attributes += nested_array_attributes
      define_validator
    end

    def self.define_equality(attr)
      @equality ||= []
      @equality << attr
      code = <<-EOR
        def ==(other)
          return false unless other
          #{@equality.inspect}.all? do |attr|
            other.respond_to?(attr) &&
              other.send(attr) == send(attr)
          end
        end
      EOR
      class_eval code
    end

    def self.define_delegate(attr, prefix = '')
      code = <<-EOR
        def #{prefix}#{attr}
          return @o[:#{attr}] if @o && @o.key?(:#{attr})
          return @t.kind_of?(Hash) ? @t[:#{attr}] : @t.#{attr} if @t
          nil
        end
      EOR
      class_eval code
    end

    def self.define_nested_delegate(attr, nested_class)
      define_delegate attr, 'get_'
      code = <<-EOR
        class << self
          def get_#{attr}_class
            @#{attr}_class
          end
          def set_#{attr}_class(arg)
            @#{attr}_class = arg
          end
          private :set_#{attr}_class
        end
      EOR

      if nested_class.kind_of? Array
        nested_class = nested_class.first
        code += <<-EOR
          def #{attr}
            return @#{attr} if defined? @#{attr}
            return [] unless val = get_#{attr}
            @#{attr} ||= val.map{|t| self.class.get_#{attr}_class.new t}
          end
          private :get_#{attr}
        EOR
      else
        code += <<-EOR
          def #{attr}
            return @#{attr} if defined? @#{attr}
            return nil unless val = get_#{attr}
            @#{attr} ||= self.class.get_#{attr}_class.new(val)
          end
          private :get_#{attr}
        EOR
      end
      class_eval code
      self.send :"set_#{attr}_class", nested_class
    end

    def self.required(*attributes)
      set_attributes(:set_required_attributes, attributes)
    end

    def self.optional(*attributes)
      set_attributes(:set_optional_attributes, attributes)
    end

    def self.set_attributes(type, attributes)
      self.define_attributes(*attributes)

      array_attributes = []
      if attributes.last.kind_of? Hash
        attributes.pop.each do |attr, nested_class|
          array_attributes << attr if nested_class.kind_of? Array
          attributes << attr
        end
      end

      self.send(type, attributes, array_attributes)
      self
    end

    define_initializer
  end

end
