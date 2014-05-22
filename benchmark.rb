$: << 'lib'
require 'bound'
require 'benchmark'

TestBoundary = Bound.required(:foo, :baz => Bound.required(:gonzo))

StructBoundary = Struct.new(:foo, :baz)
NestedStructBoundary = Struct.new(:gonzo)

def bench(key, &block)
  result = nil

  time = Benchmark.realtime { result = block.call }
  puts "Benchmarking '#{key}' --> #{time}ms"

  result
end

Provider = Class.new do
  attr_accessor :foo, :baz
  BazProvider = Class.new do
    attr_accessor :gonzo
  end
end
provider_objects = 10_000.times.map do |i|
  Provider.new.tap do |p|
    p.foo = 'YES'
    p.baz = Provider::BazProvider.new.tap do |bp|
      bp.gonzo = 22
    end
  end
end

provider_hashes = 10_000.times.map do |i|
  {
   :foo => 'YES',
   :baz => {:gonzo => 22}
  }
end


bench '      bound w/ objt' do
  provider_objects.map do |provider|
    TestBoundary.new(provider)
  end
end

bench '      bound w/ hash' do
  provider_hashes.map do |provider|
    TestBoundary.new(provider)
  end
end

bench 'structbound w/ objt' do
  provider_objects.map do |provider|
    StructBoundary.new(
                       provider.foo,
                       NestedStructBoundary.new(provider.gonzo)
                      )
  end
end

bench 'structbound w/ hash' do
  provider_hashes.map do |provider|
    StructBoundary.new(
                       provider[:foo],
                       NestedStructBoundary.new(provider[:gonzo])
                      )
  end
end
