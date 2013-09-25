require 'spec_helper'

describe Bound do
  User = Bound.new(:name, :age)

  let(:object)  { HashObject.new(hash) }
  let(:hash)    { {:name => 'foo', :age => 23} }

  it 'sets all attributes' do
    [hash, object].each do |subject|
      user = User.build(subject)

      assert_equal hash[:name], user.name
      assert_equal hash[:age], user.age
    end
  end

  it 'also sets all attributes with new instead of build' do
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
        User.build(subject)
      end

      assert_match(/missing.+age/i, exception.message)
    end
  end

  it 'works if attribute is nil' do
    hash[:age] = nil

    [hash, object].each do |subject|
      User.build(subject)
    end
  end

  it 'fails if attribute is unknown' do
    hash[:gender] = "M"
    subject = hash

    exception = assert_raises ArgumentError, subject.inspect do
      User.build(subject)
    end

    assert_match(/unknown.+gender/i, exception.message)
  end

  it 'exposes an attributes method' do
    user = User.build(hash)

    assert_equal 2, user.__attributes__.size
    assert_includes user.__attributes__, :name
    assert_includes user.__attributes__, :age
  end

  describe 'wrong initialization' do
    it 'fails if new is not called with symbols' do
      assert_raises ArgumentError do
        Bound.new(:events => [])
      end
    end

    it 'fails if optional is not called with symbols' do
      assert_raises ArgumentError do
        Bound.new.optional(:events => [])
      end
    end
  end

  describe 'inspect' do
    let(:inspection) { user.inspect }
    let(:user) { User.build(hash) }

    it 'lists all attributes' do
      assert_match(/name="foo"/, inspection)
      assert_match(/age=23/, inspection)
      assert_match(/User/, inspection)
      assert_match(/0x[0-9a-f]{14,}/, inspection)
    end

    it 'does not display @hash' do
      refute_match(/@hash={.*}/, inspection)
    end
  end

  describe 'optional attributes' do
    UserWithoutAge = Bound.new(:name).optional(:age)

    it 'sets optional attributes' do
      [hash, object].each do |subject|
        user = UserWithoutAge.build(subject)

        assert_equal hash[:age], user.age
      end
    end

    it 'works if optional attribute is missing' do
      hash.delete :age

      [hash, object].each do |subject|
        UserWithoutAge.build(subject)
      end
    end

    it 'works if attribute is nil' do
      hash[:age] = nil

      [hash, object].each do |subject|
        UserWithoutAge.build(subject)
      end
    end

    it 'are also included in attributes' do
      user = UserWithoutAge.build(hash)

      assert_equal 2, user.__attributes__.size
      assert_includes user.__attributes__, :name
      assert_includes user.__attributes__, :age
    end
  end

  describe 'no attributes' do
    UserWithoutAttributes = Bound.new
    let(:hash) { Hash.new }

    it 'works without attributes' do
      [hash, object, nil].each do |subject|
        UserWithoutAttributes.build(subject)
      end
    end

    it 'works without argument' do
      UserWithoutAttributes.build
    end
  end

  describe 'nested attribute' do
    Company       = Bound.new(:name).nested(:address => Bound.new(:street))
    EmployedUser  = Bound.new(:uid).nested(:company => Company)
    let(:hash) { {:uid => '1', :company => {:name => 'featurepoly', :address => {:street => 'Germany'}}} }

    it 'works with nested attributes' do
      [hash, object].each do |subject|
        user = EmployedUser.build(subject)

        assert_equal hash[:uid],                        user.uid
        assert_equal hash[:company][:name],             user.company.name
        assert_equal hash[:company][:address][:street], user.company.address.street
      end
    end
  end

  describe 'array of nested attribute' do
    Post          = Bound.new(:title)
    BloggingUser  = Bound.new(:name).nested(:posts => [Post])
    let(:hash) do
      {
        :name => 'Steve',
        :posts => [
          {:title => 'It is christmas'},
          {:title => 'NOT'}
        ]
      }
    end

    it 'works with array of nested attributes' do
      [hash, object].each do |subject|
        user = BloggingUser.build(subject)

        assert_equal hash[:name],             user.name
        assert_equal hash[:posts][0][:title], user.posts[0].title
        assert_equal hash[:posts][1][:title], user.posts[1].title
      end
    end

    it 'fails if posts is no array' do
      hash[:posts] = {:title => 'broken'}

      [hash, object].each do |subject|
        exception = assert_raises ArgumentError do
          BloggingUser.build(subject)
        end

        assert_match(/array/i, exception.message)
      end

    end

    it 'are also included in attributes' do
      user = BloggingUser.build(hash)

      assert_equal 2, user.__attributes__.size
      assert_includes user.__attributes__, :name
      assert_includes user.__attributes__, :posts
    end
  end

  describe 'allows optional as constructor' do
    Person = Bound.optional(:gender)

    it 'works' do
      assert_nil Person.new.gender
      assert_equal "M", Person.new(:gender => 'M').gender
    end
  end

  describe 'allows nested as constructor' do
    Car = Bound.nested(:producer => Bound.new(:name))

    it 'works' do
      assert_raises(ArgumentError) { Car.new }
      assert_equal "VW", Car.new(:producer => {:name => 'VW'}).producer.name
    end
  end
end
