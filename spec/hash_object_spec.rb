require 'spec_helper'

# Test support object
describe HashObject do

  subject { HashObject.new(the_hash) }
  let(:the_hash) do
    {
      :name => 'Steve',
      :address => {:street => 'Mainstreet'},
      :posts => [
        {:title => 'It is christmas'},
        {:title => 'NOT'}
      ],
      :living? => true
    }
  end

  it 'maps an intergalactic hash' do
    assert_equal the_hash[:name],             subject.name
    assert_equal the_hash[:address][:street], subject.address.street
    assert_equal the_hash[:posts].size,       subject.posts.size
    assert_equal the_hash[:posts][0][:title], subject.posts[0].title
    assert_equal the_hash[:posts][1][:title], subject.posts[1].title
    assert_equal the_hash[:living?],          subject.living?
  end
end
