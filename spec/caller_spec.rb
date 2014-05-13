require 'spec_helper'

describe Bound::Caller do

  it 'calls the given method with args' do
    assert_equal [22], Bound::Caller.call([], :push, 22)
  end

  it 'raises if method was not found' do
    assert_raises NoMethodError do
      Bound::Caller.call(22, :foobar)
    end
  end

end
