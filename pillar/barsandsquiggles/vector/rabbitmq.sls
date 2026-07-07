vector:
  additional_groups:
    - rabbitmq
  config:
    sources:
      source_rabbitmq_log:
        type: "file"
        file_key: "file_path"
        include:
        - /var/log/rabbitmq/rabbit@*.log

    transforms:
      parsed_rabbitmq_log:
        type: "remap"
        inputs:
          - source_rabbitmq_log
        source: |-
          . = merge(., parse_regex!(.message, r'\A(?P<timestamp>\d+-\d+-\d+\s+\d+:\d+:\d+\.\d+\+\d+:\d+)\s*\[(?P<severity>\w+)\]\s*<(?P<connection_id>[^<>]+)>\s*(?P<message>.+)'))
