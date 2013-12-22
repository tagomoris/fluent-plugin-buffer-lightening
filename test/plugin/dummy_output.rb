require 'json'

module Fluent
  class DummyBufferedOutput < BufferedOutput
    Fluent::Plugin.register_output('lightening_test', self)

    attr_reader :written

    def start
      super
      @written = []
    end

    def format(tag, time, record)
      [tag, time, record.merge({"format_time" => Time.now.to_f})].to_json + "\n"
    end

    def write(chunk)
      chunk_lines = chunk.read.split("\n").select{|line| not line.empty?}
      @written.push(* chunk.lines.map{ |line|
          p line
          tag, time, record = JSON.parse(line)
          record.update({"write_time" => Time.now.to_f})
        })
      true
    end
  end
end
