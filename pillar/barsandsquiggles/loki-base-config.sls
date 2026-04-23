loki:
  config:
    common:
      path_prefix: /var/lib/loki/data/
      replication_factor: 1
      ring:
        kvstore:
          store: memberlist
      storage:
        filesystem:
          chunks_directory: /var/lib/loki/chunks
          rules_directory:  /var/lib/loki/rules
    compactor:
      working_directory: /var/lib/loki/compactor

    query_range:
      results_cache:
        cache:
          embedded_cache:
            enabled: true
            max_size_mb: 100

    limits_config:
      metric_aggregation_enabled: true
      enable_multi_variant_queries: true
      # Rate limits
      ingestion_rate_strategy: global
      ingestion_rate_mb: 10
      ingestion_burst_size_mb: 20
      per_stream_rate_limit: 3MB
      per_stream_rate_limit_burst: 15MB

      # Stream limits
      max_global_streams_per_user: 10000
      max_streams_per_user: 0

      # Validation
      max_line_size: 256KB
      max_line_size_truncate: false
      max_label_name_length: 1024
      max_label_value_length: 2048
      max_label_names_per_series: 15

      # Time constraints
      reject_old_samples: true
      reject_old_samples_max_age: 168h  # 7 days
      creation_grace_period: 10m
      unordered_writes: True

    schema_config:
      configs:
      - from: '2023-01-01'
        index:
          period: 24h
          prefix: index_
        object_store: filesystem
        schema: v13
        store: tsdb

    frontend:
      encoding: json

    ingester:
      # Chunk settings
      chunk_idle_period: 30m
      chunk_target_size: {{ 1.5 * 1024**2 }}  # 1.5 MB
      chunk_encoding: snappy
      max_chunk_age: 2h

      # WAL settings
      wal:
        enabled: true
        checkpoint_duration: 5m
        flush_on_shutdown: true