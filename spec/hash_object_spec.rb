require 'spec_helper'

# Test support object
describe HashObject do

   subject { HashObject.new(hash) }
   let(:hash) do
     {
       :name => 'Steve', 
       :address => {:street => 'Mainstreet'},
       :posts => [
         {:title => 'It is christmas'},
         {:title => 'NOT'}
       ]
     } 
   end
  
  it 'maps an intergalactic hash' do
    assert_equal hash[:name],             subject.name
    assert_equal hash[:address][:street], subject.address.street
    assert_equal hash[:posts].size,       subject.posts.size
    assert_equal hash[:posts][0][:title], subject.posts[0].title
    assert_equal hash[:posts][1][:title], subject.posts[1].title
  end
end
