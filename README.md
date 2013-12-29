# fluent-plugin-buffer-lightening

Fluentd buffer plugin on memory to flush with many types of chunk limit methods:
  * events count limit in chunk

These options are to decrease latency from emit to write, and to control chunk sizes and flush sizes.

**NOTICE:** Lightening buffer plugin stores data on memory, so these data will be lost when process/server crashes.

## Installation

Do `gem install fluent-plugin-buffer-lightening` or `fluent-gem ...`.

## Configuration

Lightening buffer plugin can be enabled with all of buffered output plugins.

To flush chunks per 100 records, configure like this:

```
<match data.**>
  type any_buffered_output_plugin
  buffer_type lightening
  buffer_chunk_records_limit 100
  # other options...
</match>
```

Options of `buffer_type memory` are also available:
```
<match data.**>
  type any_buffered_output_plugin
  buffer_type lightening
  buffer_chunk_limit 10M
  buffer_chunk_records_limit 100
  # other options...
</match>
```

### For less delay

For more frequently flushing, use `flush_interval` and `try_flush_interval` with floating point values on Fluentd v0.10.42 or later:
```
<match data.**>
  type any_buffered_output_plugin
  buffer_type lightening
  buffer_chunk_records_limit 100
  # other options...
  flush_interval 0.5
  try_flush_interval 0.1 # 0.6sec delay for worst case
</match>
```

## TODO

* more limit patterns
* patches welcome!

## Copyright

* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
* License
  * Apache License, Version 2.0
