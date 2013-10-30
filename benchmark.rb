$: << 'lib'
require 'bound'
require 'benchmark/ips'

TestBoundary = Bound.required(:abc, :def, :ged)

ManualBoundary = Provider = Class.new do
  attr_accessor :abc, :def, :ged
end

provider = Provider.new
provider.abc = "abc"
provider.def = "def"
provider.ged = "ged"

Benchmark.ips do |x|
  x.report 'bound w/ objt' do
    TestBoundary.new(provider)
  end

  x.report 'bound w/ hash' do
    TestBoundary.new({
      :abc => provider.abc,
      :def => provider.def,
      :ged => provider.ged
    })
  end

  x.report 'plain' do
    test = ManualBoundary.new
    test.abc = provider.abc
    test.def = provider.def
    test.ged = provider.ged
  end
end
