$: << 'lib'
require 'bound'
require 'benchmark'

TestBoundary = Bound.required(
                              :foo,
                              :bar => [Bound.required(:abc)],
                              :baz => Bound.required(:gonzo)
                             )

StructBoundary = Struct.new(:foo, :bar, :baz)
BarStructBoundary = Struct.new(:abc)
BazStructBoundary = Struct.new(:gonzo)

StaticBound = Class.new do
  def initialize(target)
    @target = target
  end
end

BarStaticBoundary = Class.new(StaticBound) do
  def abc
    @target.kind_of?(Hash)?@target[:abc] : @target.abc
  end
end

BazStaticBoundary = Class.new(StaticBound) do
  def gonzo
    @target.kind_of?(Hash)?@target[:gonzo] : @target.gonzo
  end
end

StaticBoundary = Class.new(StaticBound) do
  def foo
    @target.kind_of?(Hash)?@target[:foo] : @target.foo
  end

  def bar
    @bar ||=
      (@target.kind_of?(Hash)?@target[:bar] : @target.bar).
      map { |t| BarStaticBoundary.new(t) }
  end

  def baz
    @baz ||=
      BazStaticBoundary.new(
                            (@target.kind_of?(Hash)?@target[:baz] : @target.baz)
                           )
  end
end

def assert_correctness(bound)
  raise('foo is wrong') unless bound.foo == 'YES'
  raise('bar size is wrong') unless bound.bar.size == 2
  raise('bar[0] is wrong') unless bound.bar[0].abc == 'TRUE'
  raise('bar[1] is wrong') unless bound.bar[1].abc == 'FALSE'
  raise('baz.gonzo is wrong') unless bound.baz.gonzo == 22
end

def bench(key, &block)
  result = nil

  time = Benchmark.realtime { result = block.call }
  puts "Benchmarking '#{key}' --> #{time}ms"

  result
end

Provider = Class.new do
  attr_accessor :foo, :bar, :baz
  BarProvider = Class.new do
    attr_accessor :abc
  end
  BazProvider = Class.new do
    attr_accessor :gonzo
  end
end
provider_objects = 10_000.times.map do |i|
  Provider.new.tap do |p|
    p.foo = 'YES'
    p.bar = [
             BarProvider.new.tap do |brp|
               brp.abc = 'TRUE'
             end,
             BarProvider.new.tap do |brp|
               brp.abc = 'FALSE'
             end
            ]
    p.baz = Provider::BazProvider.new.tap do |bzp|
      bzp.gonzo = 22
    end
  end
end

provider_hashes = 10_000.times.map do |i|
  {
   :foo => 'YES',
   :bar => [{:abc => 'TRUE'}, {:abc => 'FALSE'}],
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
    result = StaticBoundary.new(provider)
    assert_correctness result
  end
end

bench 'staticbound w/ hash' do
  provider_hashes.each do |provider|
    result = StaticBoundary.new(provider)
    assert_correctness result
  end
end

bench 'structbound w/ objt' do
  provider_objects.each do |provider|
    result = StructBoundary.new(
                                provider.foo,
                                [
                                 BarStructBoundary.new(provider.bar[0].abc),
                                 BarStructBoundary.new(provider.bar[1].abc),
                                ],
                                BazStructBoundary.new(provider.baz.gonzo)
                               )
    assert_correctness result
  end
end

bench 'structbound w/ hash' do
  provider_hashes.map do |provider|
    result = StructBoundary.new(
                                provider[:foo],
                                [
                                 BarStructBoundary.new(provider[:bar][0][:abc]),
                                 BarStructBoundary.new(provider[:bar][1][:abc]),
                                ],
                                BazStructBoundary.new(provider[:baz][:gonzo])
                               )
    assert_correctness result
  end
end
