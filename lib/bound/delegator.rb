class Bound
  class MissingAttributeError < RuntimeError
    def initialize(attr)
      @attr = attr
    end

    def message
      "Missing attribute '#@attr'"
    end
  end
  class NoDelegateError < RuntimeError
    def initialize(attr)
      @attr = attr
    end

    def message
      "No object for delegation of #@attr found"
    end
  end
  class Delegator
    def initialize(wrapping_class)
      @wrapping_class = wrapping_class
      @attribute_names = []
    end

    def assign(*delegates)
      @delegates = delegates
      ensure_delegation!
    end

    def register(attribute_name)
      remember attribute_name
      register_delegation_method_called attribute_name
    end

    private
    def ensure_delegation!
      @attribute_names.each do |name|
        unless @delegates.any? { |d| d.member? name }
          raise MissingAttributeError.new(name)
        end
      end
    end

    def remember(name)
      @attribute_names << name
    end

    def register_delegation_method_called(name)
      this = self
      @wrapping_class.send :define_method, name do
        this.send :delegate, name
      end
    end

    def delegate(name)
      try_delegation(name)
    end

    def try_delegation(name)
      if @delegates.nil? || @delegates.empty?
        raise(NoDelegateError.new name)
      end

      @delegates.reverse.each do |delegate|
        return delegate[name] if delegate.member? name
      end
    end
  end
end
