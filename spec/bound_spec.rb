require 'spec_helper'

describe Bound do
  User = Bound.new(:name, :age)

  let(:object)  { HashObject.new(hash) }
  let(:hash)    { {:name => 'foo', :age => 23} }

  it 'sets all attributes' do
    [hash, object].each do |subject|
      user = User.new(subject)

      assert_equal hash[:name], user.name
      assert_equal hash[:age], user.age
    end
  end

  it 'fails if attribute is missing' do
    hash.delete :age

    [hash, object].each do |subject|
      exception = assert_raises ArgumentError, subject.inspect do
        User.new(subject)
      end

      assert_match(/age/, exception.message)
    end
  end

  it 'works if attribute is nil' do
    hash[:age] = nil

    [hash, object].each do |subject|
      User.new(subject)
    end
  end

  describe 'optional attributes' do
    UserWithoutAge = Bound.new(:name, :optional => [:age])

    it 'sets optional attributes' do
      [hash, object].each do |subject|
        user = UserWithoutAge.new(subject)

        assert_equal hash[:age], user.age
      end
    end

    it 'works if optional attribute is missing' do
      hash.delete :age

      [hash, object].each do |subject|
        UserWithoutAge.new(subject)
      end
    end

    it 'works if attribute is nil' do
      hash[:age] = nil

      [hash, object].each do |subject|
        UserWithoutAge.new(subject)
      end
    end
  end
end
