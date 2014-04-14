require 'fluent/plugin/buf_memory'

module Fluent
  class LighteningBufferChunk < MemoryBufferChunk
    attr_reader :record_counter

    def initialize(key, data='')
      super
      @record_counter = 0
    end

    def <<(data)
      super
      @record_counter += 1
    end
  end

  class LighteningBuffer < MemoryBuffer
    Fluent::Plugin.register_buffer('lightening', self)

    config_param :buffer_chunk_records_limit, :integer, :default => nil

    def configure(conf)
      super
    end

    def new_chunk(key)
      LighteningBufferChunk.new(key)
    end

    def storable?(chunk, data)
      return false if chunk.size + data.bytesize > @buffer_chunk_limit
      return false if @buffer_chunk_records_limit && chunk.record_counter >= @buffer_chunk_records_limit
      true
    end

    # TODO: remove w/ fluentd v0.10.42 (or td-agent including fluentd v0.10.42)
    def emit(key, data, chain) # copy&paste from BasicBuffer, and fix to add hook point
      key = key.to_s

      synchronize do
        top = (@map[key] ||= new_chunk(key))

        if storable?(top, data) # hook point (FIXED THIS LINE ONLY)
          chain.next
          top << data
          return false
        elsif @queue.size >= @buffer_queue_limit
          raise BufferQueueLimitError, "queue size exceeds limit"
        end

        if data.bytesize > @buffer_chunk_limit
          $log.warn "Size of the emitted data exceeds buffer_chunk_limit."
          $log.warn "This may occur problems in the output plugins ``at this server.``"
          $log.warn "To avoid problems, set a smaller number to the buffer_chunk_limit"
          $log.warn "in the forward output ``at the log forwarding server.``"
        end

        nc = new_chunk(key)
        ok = false

        begin
          nc << data
          chain.next

          flush_trigger = false
          @queue.synchronize {
            enqueue(top)
            flush_trigger = @queue.empty?
            @queue << top
            @map[key] = nc
          }

          ok = true
          return flush_trigger
        ensure
          nc.purge unless ok
        end

      end  # synchronize
    end
  end
end
