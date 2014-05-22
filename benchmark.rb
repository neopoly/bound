$: << 'lib'
require 'bound'
require 'benchmark'

TestBoundary = Bound.required(:foo, :baz => Bound.required(:gonzo))

StructBoundary = Struct.new(:foo, :baz)
NestedStructBoundary = Struct.new(:gonzo)

StaticBound = Class.new do
  def initialize(target)
    @target = target
  end
end

StaticObjBoundary = Class.new(StaticBound) do
  def foo
    @target.foo
  end

  def baz
    @baz ||= BazObjBoundary.new(@target.baz)
  end

  BazObjBoundary = Class.new(StaticBound) do
    def gonzo
      @target.gonzo
    end
  end
end

StaticHashBoundary = Class.new(StaticBound) do
  def foo
    @target[:foo]
  end

  def baz
    @baz ||= BazHashBoundary.new(@target[:baz])
  end

  BazHashBoundary = Class.new(StaticBound) do
    def gonzo
      @target[:gonzo]
    end
  end
end


def assert_correctness(bound)
  raise('foo is wrong') unless bound.foo == 'YES'
  raise('baz.gonzo is wrong') unless bound.baz.gonzo == 22
end

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
  provider_objects.each do |provider|
    result = TestBoundary.new(provider)
    assert_correctness result
  end
end

bench '      bound w/ hash' do
  provider_hashes.each do |provider|
    result = TestBoundary.new(provider)
    assert_correctness result
  end
end

bench 'staticbound w/ objt' do
  provider_objects.each do |provider|
    result = StaticObjBoundary.new(provider)
    assert_correctness result
  end
end

bench 'staticbound w/ hash' do
  provider_hashes.each do |provider|
    result = StaticHashBoundary.new(provider)
    assert_correctness result
  end
end

bench 'structbound w/ objt' do
  provider_objects.each do |provider|
    result = StructBoundary.new(
                                provider.foo,
                                NestedStructBoundary.new(provider.baz.gonzo)
                               )
    assert_correctness result
  end
end

bench 'structbound w/ hash' do
  provider_hashes.map do |provider|
    result = StructBoundary.new(
                                provider[:foo],
                                NestedStructBoundary.new(provider[:baz][:gonzo])
                               )
    assert_correctness result
  end
end
