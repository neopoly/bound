$: << 'lib'
require 'bound'
require 'benchmark/ips'

Nested = Struct.new(:yo)

TestBoundary = Bound.required(:abc, :def, :ged, :yo => Nested)

ManualBoundary = Provider = Class.new do
  attr_accessor :abc, :def, :ged, :yo
end

NestedBoundary = Bound.required(:yo)

nested = Nested.new
nested.yo = 23

provider = Provider.new
provider.abc = "abc"
provider.def = "def"
provider.ged = "ged"
provider.yo = nested

TestBoundary.new(provider)

Benchmark.ips do |x|
  x.report 'bound w/ objt' do
    TestBoundary.new(provider)
  end

  x.report 'bound w/ hash' do
    TestBoundary.new({
      :abc => provider.abc,
      :def => provider.def,
      :ged => provider.ged,
      :yo  => nested
    })
  end

  x.report 'plain' do
    test = ManualBoundary.new
    test.abc = provider.abc
    test.def = provider.def
    test.ged = provider.ged
    test.yo  = nested
  end
end
