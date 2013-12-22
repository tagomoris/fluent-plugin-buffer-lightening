# MEMO: execute fluentd with "-r fluent/plugin/output_try_flush_interval_patch" switch

# TODO: remove w/ fluentd v0.10.42 (or td-agent including fluentd v0.10.42)
module Fluent
  class BufferedOutput < Output
    config_param :try_flush_interval, :float, :default => 1

    # override with @try_flush_interval
    def try_flush
      time = Engine.now

      empty = @buffer.queue_size == 0
      if empty && @next_flush_time < (now = Engine.now)
        @buffer.synchronize do
          if @next_flush_time < now
            enqueue_buffer
            @next_flush_time = now + @flush_interval
            empty = @buffer.queue_size == 0
          end
        end
      end
      if empty
        return time + @try_flush_interval
      end

      begin
        retrying = !@error_history.empty?

        if retrying
          @error_history.synchronize do
            if retrying = !@error_history.empty?  # re-check in synchronize
              if @next_retry_time >= time
                # allow retrying for only one thread
                return time + @try_flush_interval
              end
              # assume next retry failes and
              # clear them if when it succeeds
              @last_retry_time = time
              @error_history << time
              @next_retry_time += calc_retry_wait
            end
          end
        end

        if @secondary && @error_history.size > @retry_limit
          has_next = flush_secondary(@secondary)
        else
          has_next = @buffer.pop(self)
        end

        # success
        if retrying
          @error_history.clear
          # Note: don't notify to other threads to prevent
          #       burst to recovered server
          $log.warn "retry succeeded.", :instance=>object_id
        end

        if has_next
          return Engine.now + @queued_chunk_flush_interval
        else
          return time + @try_flush_interval
        end

      rescue => e
        if retrying
          error_count = @error_history.size
        else
          # first error
          error_count = 0
          @error_history.synchronize do
            if @error_history.empty?
              @last_retry_time = time
              @error_history << time
              @next_retry_time = time + calc_retry_wait
            end
          end
        end

        if error_count < @retry_limit
          $log.warn "temporarily failed to flush the buffer.", :next_retry=>Time.at(@next_retry_time), :error_class=>e.class.to_s, :error=>e.to_s, :instance=>object_id
          $log.warn_backtrace e.backtrace

        elsif @secondary
          if error_count == @retry_limit
            $log.warn "failed to flush the buffer.", :error_class=>e.class.to_s, :error=>e.to_s, :instance=>object_id
            $log.warn "retry count exceededs limit. falling back to secondary output."
            $log.warn_backtrace e.backtrace
            retry  # retry immediately
          elsif error_count <= @retry_limit + @secondary_limit
            $log.warn "failed to flush the buffer, next retry will be with secondary output.", :next_retry=>Time.at(@next_retry_time), :error_class=>e.class.to_s, :error=>e.to_s, :instance=>object_id
            $log.warn_backtrace e.backtrace
          else
            $log.warn "failed to flush the buffer.", :error_class=>e.class, :error=>e.to_s, :instance=>object_id
            $log.warn "secondary retry count exceededs limit."
            $log.warn_backtrace e.backtrace
            write_abort
            @error_history.clear
          end

        else
          $log.warn "failed to flush the buffer.", :error_class=>e.class.to_s, :error=>e.to_s, :instance=>object_id
          $log.warn "retry count exceededs limit."
          $log.warn_backtrace e.backtrace
          write_abort
          @error_history.clear
        end

        return @next_retry_time
      end
    end
  end
end
