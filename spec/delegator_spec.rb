require 'spec_helper'

describe Bound::Delegator do
  attr_reader :wrapping_class, :delegator

  before do
    @wrapping_class = Class.new
    @delegator = Bound::Delegator.new(@wrapping_class)
  end

  describe 'registration' do
    before do
      delegator.register :a_method
      delegator.register :second_method
    end

    it 'creates a method with the same name on the wrapping class' do
      assert_includes wrapping_class.instance_methods, :a_method
    end

    describe 'without assignments' do
      it 'fails with an explicit error' do
        assert_raises Bound::NoDelegateError do
          wrapping_class.new.a_method
        end
      end
    end

    describe 'with single hash assignment' do
      before do
        @hash = {:a_method => 42, :second_method => 11}
      end

      it 'delegates to the key of the assigned hash' do
        delegator.assign @hash
        assert_equal 42, wrapping_class.new.a_method
      end

      describe 'and a second hash assignment' do
        before do
          @hash2 = {:a_method => 84}
        end

        it 'overwrites the value of the first hash' do
          delegator.assign @hash, @hash2
          assert_equal 84, wrapping_class.new.a_method
        end
      end
    end

    describe 'with wrong hash assignment' do
      before do
        @hash = {:a_method => 42}
      end

      it 'raises an error on delegation' do
        assert_raises Bound::MissingAttributeError do
          delegator.assign @hash
        end
      end

      it 'raises no error if the second assign has the missing key' do
        delegator.assign @hash, :second_method => 43
        assert_equal 43, wrapping_class.new.second_method
      end
    end

    describe 'with optional attribute' do
      before do
        delegator.register_optional :opt
        @hash = {:a_method => 42, :second_method => 11, :opt => '33'}
      end

      it 'also delegates' do
        delegator.assign @hash
        assert_equal '33', wrapping_class.new.opt
      end

      it 'does not raise if this value is missing on assignment' do
        @hash.delete :opt
        delegator.assign @hash
        assert_nil wrapping_class.new.opt
      end
    end
  end
end
