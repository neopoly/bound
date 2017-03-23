require 'spec_helper'

describe Bound do
  User = Bound.required(:name, :age)

  let(:object)  { HashObject.new(the_hash) }
  let(:the_hash)    { {:name => 'foo', :age => 23} }

  it 'sets all attributes' do
    [the_hash, object].each do |subject|
      user = User.new(subject)

      assert_equal the_hash[:name], user.name
      assert_equal the_hash[:age], user.age
    end
  end

  it 'does not cache the set attributes' do
    user = User.new(the_hash)
    the_hash[:name] = 'AAA'
    assert_equal 'AAA', user.name

    user = User.new(object)
    object.name = 'AAA'
    assert_equal 'AAA', user.name
  end

  it 'fails if attribute is missing' do
    the_hash.delete :age

    [the_hash, object].each do |subject|
      exception = assert_raises MissingAttributeError, subject.inspect do
        User.new(subject)
      end

      assert_match(/missing.+age/i, exception.message)
    end
  end

  it 'works if attribute is nil' do
    the_hash[:age] = nil

    [the_hash, object].each do |subject|
      User.new(subject)
    end
  end

  it 'fails if attribute is unknown' do
    the_hash[:gender] = "M"
    subject = the_hash

    exception = assert_raises UnknownAttributeError, subject.inspect do
      User.new(subject)
    end

    assert_match(/unknown.+gender/i, exception.message)
  end

  describe 'equality' do
    let(:user) { User.new(the_hash) }

    it 'is given if all the attributes are same' do
      reference_user = User.new(the_hash)

      assert_equal user, reference_user
    end

    it 'is not given if attributes differ' do
      reference_user = User.new(the_hash.merge(:name => 'DIFF'))

      refute_equal user, reference_user
    end

    it 'is given for other objects with same signature' do
      reference_user = Struct.new(:name, :age).new(user.name, user.age)

      assert_equal user, reference_user
    end

    it 'is not given for nil' do
      refute_equal user, nil
    end
  end

  describe 'wrong initialization' do
    it 'fails if new is not called with symbols' do
      assert_raises ArgumentError do
        Bound.required(32, "a")
      end
    end

    it 'fails if optional is not called with symbols' do
      assert_raises ArgumentError do
        Bound.required(32, "a")
      end
    end
  end

  describe 'inspect' do
    let(:inspection) { user.inspect }
    let(:user) { User.new(the_hash) }

    it 'lists all attributes' do
      assert_match(/name=>"foo"/, inspection)
      assert_match(/age=>23/, inspection)
      assert_match(/User/, inspection)
      assert_match(/0x[0-9a-f]+/, inspection)
    end

    it 'does not display @hash' do
      refute_match(/@hash=/, inspection)
    end
  end

  describe 'optional attributes' do
    UserWithoutAge = Bound.required(:name).optional(:age)

    it 'sets optional attributes' do
      [the_hash, object].each do |subject|
        user = UserWithoutAge.new(subject)

        assert_equal the_hash[:age], user.age
      end
    end

    it 'works if optional attribute is missing' do
      the_hash.delete :age

      [the_hash, object].each do |subject|
        UserWithoutAge.new(subject)
      end
    end

    it 'works if attribute is nil' do
      the_hash[:age] = nil

      [the_hash, object].each do |subject|
        UserWithoutAge.new(subject)
      end
    end
  end

  describe 'optional nested attributes' do
    UserWithProfile = Bound.required(:id).optional(
      :profile => Bound.required(:age)
    )
    let(:the_hash) do
      {
        :id => 12,
        :profile => {
          :age => 23
        }
      }
    end

    it 'sets optional attributes' do
      [the_hash, object].each do |subject|
        user = UserWithProfile.new(subject)

        assert_equal the_hash[:profile][:age], user.profile.age
      end
    end

    it 'works if optional attribute is missing' do
      the_hash.delete :profile

      [the_hash, object].each do |subject|
        UserWithProfile.new(subject)
      end
    end

    it 'fails if argument of optional nested bound is missing' do
      the_hash[:profile].delete(:age)
      [the_hash, object].each do |subject|
        error = assert_raises MissingAttributeError do
          UserWithProfile.new(subject)
        end
        assert_match(/missing/i, error.message)
      end
    end
  end

  describe 'no attributes' do
    UserWithoutAttributes = Bound.new
    let(:the_hash) { Hash.new }

    it 'works without attributes' do
      [the_hash, object, nil].each do |subject|
        UserWithoutAttributes.new(subject)
      end
    end

    it 'works without argument' do
      UserWithoutAttributes.new
    end
  end

  describe 'nested attribute' do
    Company       = Bound.required(:name, :address => Bound.required(:street))
    EmployedUser  = Bound.required(:uid, :company => Company)
    let(:the_hash) { {:uid => '1', :company => {:name => 'featurepoly', :address => {:street => 'Germany'}}} }

    it 'works with nested attributes' do
      [the_hash, object].each do |subject|
        user = EmployedUser.new(subject)

        assert_equal the_hash[:uid],                        user.uid
        assert_equal the_hash[:company][:name],             user.company.name
        assert_equal the_hash[:company][:address][:street], user.company.address.street
      end
    end

    it 'fails if nested attributes are missing' do
      the_hash[:company].delete(:name)
      [the_hash, object].each do |subject|
        error = assert_raises MissingAttributeError do
          EmployedUser.new(subject)
        end
        assert_match(/missing/i, error.message)
      end
    end

    it 'does not cache values in the nested bound' do
      user = EmployedUser.new(the_hash)
      the_hash[:company][:name] = 'AAA'
      assert_equal 'AAA', user.company.name

      user = EmployedUser.new(object)
      object.company.name = 'AAA'
      assert_equal 'AAA', user.company.name
    end
  end

  describe 'array of nested attribute' do
    Post          = Bound.required(:title)
    BloggingUser  = Bound.required(:name, :posts => [Post])
    let(:the_hash) do
      {
        :name => 'Steve',
        :posts => [
          {:title => 'It is christmas'},
          {:title => 'NOT'}
        ]
      }
    end

    it 'works with array of nested attributes' do
      [the_hash, object].each do |subject|
        user = BloggingUser.new(subject)

        assert_equal the_hash[:name],             user.name
        assert_equal the_hash[:posts][0][:title], user.posts[0].title
        assert_equal the_hash[:posts][1][:title], user.posts[1].title
      end
    end

    it 'fails if nested bound is missing an attribute' do
      the_hash[:posts][1].delete(:title)
      [the_hash, object].each do |subject|
        error = assert_raises MissingAttributeError do
          BloggingUser.new(subject)
        end
        assert_match(/missing/i, error.message)
      end
    end

    it 'does not cache values in the array' do
      user = BloggingUser.new(the_hash)
      the_hash[:posts][0][:title] = 'AAA'
      assert_equal 'AAA', user.posts[0].title

      user = BloggingUser.new(object)
      object.posts[0].title = 'AAA'
      assert_equal 'AAA', user.posts[0].title
    end

    describe 'equality' do
      let(:user) { BloggingUser.new(the_hash) }
      it 'is given if the nested attributes are equal' do
        assert_equal BloggingUser.new(the_hash), user
      end

      it 'is not given if nested attributes differ' do
        second_hash = Marshal.load(Marshal.dump the_hash)
        second_hash[:posts][0][:title] = 'DIFFERENT'

        refute_equal BloggingUser.new(second_hash), user
      end
    end

    it 'fails if posts is no array' do
      the_hash[:posts] = {:title => 'broken'}

      [the_hash, object].each do |subject|
        exception = assert_raises ArgumentError do
          BloggingUser.new(subject)
        end

        assert_match(/array/i, exception.message)
      end

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
    Car = Bound.required(:producer => Bound.required(:name))

    it 'works' do
      assert_raises(ArgumentError) { Car.new }
      assert_equal "VW", Car.new(:producer => {:name => 'VW'}).producer.name
    end
  end

  describe 'questionmark suffix' do
    WonderingUser = Bound.required(:asked?)

    let(:the_hash)    { {:asked? => "YES"} }

    it 'is assign- and readable' do
      [the_hash, object].each do |subject|
        user = WonderingUser.new(subject)
        assert_equal "YES", user.asked?
      end
    end
  end

  describe 'seeding with private methods' do
    ShyUser = Bound.required(:secret)
    UserSeed = Class.new do
      private
      def secret; 42; end
    end

    it 'fails like the method does not exists' do
      exception = assert_raises ArgumentError do
        ShyUser.new(UserSeed.new)
      end

      assert_match(/missing.+secret/i, exception.message)
    end
  end

  describe 'seeding with multiple seeds' do
    FunnyUser = Bound.required(:joke, :nose_color)

    let(:the_hash) { {:joke => 'Text', :nose_color => 'blue'} }

    it 'overwrites attributes from first to last' do
      overwriting_hash = {:nose_color => 'RED'}

      [the_hash, object].each do |subject|
        user = FunnyUser.new(subject, overwriting_hash)

        assertion_description = [subject, overwriting_hash].inspect
        assert_equal 'RED', user.nose_color, assertion_description
      end
    end
  end

  describe 'bug: raises error if optional attribute does not exist in input' do
    Person = Bound.optional(:gender)

    let(:the_hash) { {} }
    let(:object)   { HashObject.new({}) }

    it 'for object' do
      person = Person.new(object)
      assert_nil person.gender
    end

    it 'for hash' do
      person = Person.new(the_hash)
      assert_nil person.gender
    end
  end

end
