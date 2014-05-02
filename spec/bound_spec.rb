require 'spec_helper'

describe Bound do
  User = Bound.required(:name, :age)

  let(:object)  { HashObject.new(hash) }
  let(:hash)    { {:name => 'foo', :age => 23} }

  it 'sets all attributes' do
    [hash, object].each do |subject|
      user = User.new(subject)

      assert_equal hash[:name], user.name
      assert_equal hash[:age], user.age
    end
  end

  it 'checks if attribute exists' do
    [hash, object].each do |subject|
      user = User.new(subject)

      assert user.has_attribute?(:name)
      assert user.has_attribute?(:age)
    end
  end

  it 'fails if attribute is missing' do
    hash.delete :age

    [hash, object].each do |subject|
      exception = assert_raises ArgumentError, subject.inspect do
        User.new(subject)
      end

      assert_match(/missing.+age/i, exception.message)
    end
  end

  it 'works if attribute is nil' do
    hash[:age] = nil

    [hash, object].each do |subject|
      User.new(subject)
    end
  end

  it 'fails if attribute is unknown' do
    hash[:gender] = "M"
    subject = hash

    exception = assert_raises ArgumentError, subject.inspect do
      User.new(subject)
    end

    assert_match(/unknown.+gender/i, exception.message)
  end

  it 'exposes an attributes method' do
    skip
    user = User.new(hash)

    assert_equal 2, user.get_attributes.size
    assert_includes user.get_attributes.map(&:name), :name
    assert_includes user.get_attributes.map(&:name), :age
  end

  describe 'equality' do
    before do
      skip
    end
    let(:user) { User.new(hash) }

    it 'is given if all the attributes are same' do
      reference_user = User.new(hash)

      assert_equal user, reference_user
    end

    it 'is not given if attributes differ' do
      reference_user = User.new(hash.merge(:name => 'DIFF'))

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
    let(:user) { User.new(hash) }

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

    it 'are also included in attributes' do
      skip
      user = UserWithoutAge.new(hash)

      assert_equal 2, user.get_attributes.size
      assert_includes user.get_attributes.map(&:name), :name
      assert_includes user.get_attributes.map(&:name), :age
    end
  end

  describe 'optional nested attributes' do
    UserWithProfile = Bound.required(:id).optional(
      :profile => Bound.required(:age)
    )
    let(:hash) do
      {
        :id => 12,
        :profile => {
          :age => 23
        }
      }
    end

    it 'sets optional attributes' do
      [hash, object].each do |subject|
        user = UserWithProfile.new(subject)

        assert_equal hash[:profile][:age], user.profile.age
      end
    end

    it 'works if optional attribute is missing' do
      hash.delete :profile

      [hash, object].each do |subject|
        UserWithProfile.new(subject)
      end
    end

    it 'are also included in attributes' do
      user = UserWithProfile.new(hash)

      assert_equal 2, user.get_attributes.size
      assert_includes user.get_attributes.map(&:name), :id
      assert_includes user.get_attributes.map(&:name), :profile
    end
  end

  describe 'no attributes' do
    UserWithoutAttributes = Bound.new
    let(:hash) { Hash.new }

    it 'works without attributes' do
      [hash, object, nil].each do |subject|
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
    let(:hash) { {:uid => '1', :company => {:name => 'featurepoly', :address => {:street => 'Germany'}}} }

    it 'works with nested attributes' do
      [hash, object].each do |subject|
        user = EmployedUser.new(subject)

        assert_equal hash[:uid],                        user.uid
        assert_equal hash[:company][:name],             user.company.name
        assert_equal hash[:company][:address][:street], user.company.address.street
      end
    end
  end

  describe 'array of nested attribute' do
    Post          = Bound.required(:title)
    BloggingUser  = Bound.required(:name, :posts => [Post])
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
        user = BloggingUser.new(subject)

        assert_equal hash[:name],             user.name
        assert_equal hash[:posts][0][:title], user.posts[0].title
        assert_equal hash[:posts][1][:title], user.posts[1].title
      end
    end

    describe 'equality' do
      let(:user) { BloggingUser.new(hash) }
      it 'is given if the nested attributes are equal' do
        assert_equal BloggingUser.new(hash), user
      end

      it 'is not given if nested attributes differ' do
        second_hash = Marshal.load(Marshal.dump hash)
        second_hash[:posts][0][:title] = 'DIFFERENT'

        refute_equal BloggingUser.new(second_hash), user
      end
    end

    it 'fails if posts is no array' do
      hash[:posts] = {:title => 'broken'}

      [hash, object].each do |subject|
        exception = assert_raises ArgumentError do
          BloggingUser.new(subject)
        end

        assert_match(/array/i, exception.message)
      end

    end

    it 'are also included in attributes' do
      user = BloggingUser.new(hash)

      assert_equal 2, user.get_attributes.size
      assert_includes user.get_attributes.map(&:name), :name
      assert_includes user.get_attributes.map(&:name), :posts
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

  describe '__attributes__' do
    DeprecatedUser = Bound.required(:name)

    it 'is deprecated' do
      user = DeprecatedUser.new(:name => 'foo')

      deprecation_warning, _ = capture_io do
        user.__attributes__
      end

      assert_match(/deprecated/, deprecation_warning)
    end
  end

  describe 'questionmark suffix' do
    WonderingUser = Bound.required(:asked?)

    let(:hash)    { {:asked? => "YES"} }

    it 'is assign- and readable' do
      [hash, object].each do |subject|
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

    let(:hash) { {:joke => 'Text', :nose_color => 'blue'} }

    it 'overwrites attributes from first to last' do
      overwriting_hash = {:nose_color => 'RED'}
      overwriting_object = HashObject.new(overwriting_hash)

      [hash, object].each do |subject|
        [overwriting_hash, overwriting_object].each do |overwriting_subject|
          user = FunnyUser.new(subject, overwriting_subject)

          assertion_description = [subject, overwriting_subject].inspect
          assert_equal 'RED', user.nose_color, assertion_description
        end
      end
    end
  end


end
