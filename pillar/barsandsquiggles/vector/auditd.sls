vector:
  additional_groups:
    - audit
  config:
    sources:
      source_audit_log:
        type: "file"
        file_key: "file_path"
        max_line_bytes: 102400000
        include:
        - /var/log/audit/audit.log

    transforms:
      parsed_audit_log:
        type: "remap"
        inputs:
          - source_audit_log
        source: |-
          . = merge(., parse_regex!(.message, r'type=(?P<type>\S+)\s+msg=audit\((?P<unix_timestamp>\d+\.\d+):(?P<pid>\d+)\):\s+(?P<audit_message>.*)'))
          . = merge(., parse_logfmt!(.audit_message))
          .timestamp = from_unix_timestamp!(value:  to_int(to_float!(.unix_timestamp)*1000), unit: "milliseconds")
          del(.message)
          del(.audit_message)