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

    def initialize(delegate)
      assign_delegate delegate
    end

    private
    def assign_delegate(delegate)
      self.class.send(:delegator).assign delegate
    end
  end

end
