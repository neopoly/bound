require 'bound/delegator'

class Bound
  module DSL
    def new_child
      Class.new(self)
    end

    def required(*attributes)
      attributes.each do |attribute|
        delegator.register attribute
      end
      self
    end

    private
    def delegator
      @delegator ||= Delegator.new(self)
    end
  end

  class FastBound
    extend DSL

    def initialize(*delegates)
      assign_delegates(*delegates)
    end

    private
    def assign_delegates(*delegates)
      self.class.send(:delegator).assign(*delegates)
    end
  end

end
