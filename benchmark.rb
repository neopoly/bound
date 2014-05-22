$: << 'lib'
require 'bound'
require 'benchmark'

#Bound.disable_validation

TestBoundary = Bound.required(
                              :foo,
                              :bar => [Bound.required(:abc)],
                              :baz => Bound.required(:gonzo)
                             )

StructBoundary = Struct.new(:foo, :bar, :baz)
BarStructBoundary = Struct.new(:abc)
BazStructBoundary = Struct.new(:gonzo)

StaticBoundClass = Class.new do
  def self.initialize_unvalidated
    class_eval <<-EOR
      def initialize(target, overwrite = nil)
        @t, @o = target, overwrite
      end
    EOR
  end

  def self.define_delegate(attr, prefix = '')
    class_eval <<-EOR
      def #{prefix}#{attr}
        return @o[:#{attr}] if @o && @o.key?(:#{attr})
        @t.kind_of?(Hash)? @t[:#{attr}] : @t.#{attr}
      end
    EOR
  end

  def self.define_nested_delegate(attr, nested_class)
    define_delegate attr, 'get_'
    if nested_class.kind_of? Array
      nested_class = nested_class.first
      class_eval <<-EOR
        def #{attr}
          @#{attr} ||= get_#{attr}.map{|t| #{nested_class}.new t}
        end
        private :get_#{attr}
      EOR
    else
      class_eval <<-EOR
        def #{attr}
          @#{attr} ||= #{nested_class}.new(get_#{attr})
        end
        private :get_#{attr}
      EOR
    end
  end
end

BarStaticBoundary = Class.new(StaticBoundClass) do
  initialize_unvalidated

  define_delegate :abc
end

BazStaticBoundary = Class.new(StaticBoundClass) do
  initialize_unvalidated

  define_delegate :gonzo
end

StaticBoundary = Class.new(StaticBoundClass) do
  initialize_unvalidated

  define_delegate :foo
  define_nested_delegate :bar, [BarStaticBoundary]
  define_nested_delegate :baz, BazStaticBoundary
end

def assert_correctness(bound)
  raise('foo is wrong') unless bound.foo == 'NOPE'
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
provider_objects = 100_000.times.map do |i|
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
    p.baz = BazProvider.new.tap do |bzp|
      bzp.gonzo = 22
    end
  end
end

provider_hashes = 100_000.times.map do |i|
  {
   :foo => 'YES',
   :bar => [{:abc => 'TRUE'}, {:abc => 'FALSE'}],
   :baz => {:gonzo => 22}
  }
end

overwrite = {:foo => 'NOPE'}

bench '      bound w/ objt' do
  provider_objects.each do |provider|
    result = TestBoundary.new(provider, overwrite)
    assert_correctness result
  end
end

bench '      bound w/ hash' do
  provider_hashes.each do |provider|
    result = TestBoundary.new(provider, overwrite)
    assert_correctness result
  end
end

bench 'staticbound w/ objt' do
  provider_objects.each do |provider|
    result = StaticBoundary.new(provider, overwrite)
    assert_correctness result
  end
end

bench 'staticbound w/ hash' do
  provider_hashes.each do |provider|
    result = StaticBoundary.new(provider, overwrite)
    assert_correctness result
  end
end

bench 'structbound w/ objt' do
  provider_objects.each do |provider|
    result = StructBoundary.new(
                                overwrite[:foo],
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
                                overwrite[:foo],
                                [
                                 BarStructBoundary.new(provider[:bar][0][:abc]),
                                 BarStructBoundary.new(provider[:bar][1][:abc]),
                                ],
                                BazStructBoundary.new(provider[:baz][:gonzo])
                               )
    assert_correctness result
  end
end
