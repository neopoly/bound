$: << 'lib'
require 'bound'
require 'benchmark'

TestBoundary = Bound.required(:abc, :def, :ged)

ManualBoundary = Provider = Class.new do
  attr_accessor :abc, :def, :ged
end

def bench(key, &block)
  result = nil

  time = Benchmark.realtime { result = block.call }
  puts "Benchmarking '#{key}' --> #{time}ms"

  result
end

providers = 10_000.times.map do |i|
  provider = Provider.new
  provider.abc = "abc#{i}"
  provider.def = "def#{i}"
  provider.ged = "ged#{i}"
  provider
end

bench 'bound w/ objt' do
  providers.map do |provider|
    TestBoundary.new(provider)
  end
end

bench 'bound w/ hash' do
  providers.map do |provider|
    TestBoundary.new({
      :abc => provider.abc,
      :def => provider.def,
      :ged => provider.ged
    })
  end
end

bench 'plain' do
  providers.map do |provider|
    test = ManualBoundary.new
    test.abc = provider.abc
    test.def = provider.def
    test.ged = provider.ged
    test
  end
end
