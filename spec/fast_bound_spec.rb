require 'spec_helper'

describe Bound::FastBound do

  let(:bound) do
    bound_class.new(obj)
  end

  describe 'without nesting' do
    let(:bound_class) do
      Bound::FastBound.new_child.required(:foo, :bar)
    end

    describe 'and a call with a hash' do
      let(:obj) { {:foo => 1, :bar => 42, :baz => 22} }

      it 'just delegates to the keys' do
        assert_equal 1, bound.foo
        assert_equal 42, bound.bar
      end

      describe 'which is missing a value' do
        before do
          obj.delete(:foo)
        end

        it 'raises an error' do
          assert_raises Bound::MissingAttributeError do
            bound
          end
        end
      end
    end
  end
end
