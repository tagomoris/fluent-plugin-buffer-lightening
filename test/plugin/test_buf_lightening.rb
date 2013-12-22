require 'helper'
require_relative 'dummy_output'

class DummyChain
  def next
  end
end

class LighteningBufferTest < Test::Unit::TestCase
  CONFIG = %[
    buffer_type lightening
    flush_interval 0.1
    try_flush_interval 0.03
    buffer_chunk_records_limit 10
]

  def create_driver(conf=CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::DummyBufferedOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver
    assert d.instance # successfully configured
    assert_equal 0.1,  d.instance.flush_interval
    assert_equal 0.03, d.instance.try_flush_interval
    assert_equal 10,   d.instance.instance_eval{ @buffer }.buffer_chunk_records_limit
  end

  def test_emit
    d = create_driver
    buffer = d.instance.instance_eval{ @buffer }
    assert buffer
    buffer.start

    assert_nil buffer.instance_eval{ @map[''] }

    d.emit({"a" => 1})
    assert_equal 1, buffer.instance_eval{ @map[''] }.record_counter

    d.emit({"a" => 2}); d.emit({"a" => 3}); d.emit({"a" => 4})
    d.emit({"a" => 5}); d.emit({"a" => 6}); d.emit({"a" => 7});
    d.emit({"a" => 8});
    assert_equal 8, buffer.instance_eval{ @map[''] }.record_counter

    chain = DummyChain.new
    tag = d.instance.instance_eval{ @tag }
    time = Time.now.to_i

    assert !buffer.emit(tag, d.instance.format(tag, time, {"a" => 9}), chain) # flush_trigger false
    assert_equal 9, buffer.instance_eval{ @map[''] }.record_counter

    assert !buffer.emit(tag, d.instance.format(tag, time, {"a" => 10}), chain) # flush_trigger false
    assert_equal 10, buffer.instance_eval{ @map[''] }.record_counter

    assert buffer.emit(tag, d.instance.format(tag, time, {"a" => 11}), chain) # flush_trigger true
    assert_equal 1, buffer.instance_eval{ @map[''] }.record_counter # new chunk

    assert !buffer.emit(tag, d.instance.format(tag, time, {"a" => 12}), chain) # flush_trigger false
    assert_equal 2, buffer.instance_eval{ @map[''] }.record_counter
  end

end
