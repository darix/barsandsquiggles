vector:
  config:
    sources:
      apache_access_logs_common:
        type: file
        file_key: "file_path"
        include: []
      apache_access_logs_combined:
        type: file
        file_key: "file_path"
        include:
        - /var/log/apache2/access_log
      apache_error_logs:
        type: file
        file_key: "file_path"
        include:
          - /var/log/apache2/error_log

    transforms:
      parsed_apache_access_logs_common:
        type: remap
        inputs:
          - apache_access_logs_common
        source: |-
          . = merge(., parse_apache_log!(.message, format: "common"))

      parsed_apache_access_logs_combined:
        type: remap
        inputs:
          - apache_access_logs_combined
        source: |-
          . = merge(., parse_apache_log!(.message, format: "combined"))

      parsed_apache_error_logs:
        type: remap
        inputs:
          - apache_error_logs
        source: |-
          . = merge(., parse_apache_log!(.message, format: "error"))
