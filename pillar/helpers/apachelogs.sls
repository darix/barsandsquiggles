{%- macro apache_logs_sources(common_logs=[], combined_logs=['/var/log/apache2/access_log'], error_logs=['/var/log/apache2/error_log'], logfmt_logs=[], json_logs=[]) %}
{%- if common_logs | length > 0 %}
      apache_access_logs_common:
        type: file
        file_key: "file_path"
        include: {{ common_logs }}
{%- endif %}
{%- if combined_logs | length > 0 %}
      apache_access_logs_combined:
        type: file
        file_key: "file_path"
        include: {{ combined_logs }}
{%- endif %}
{%- if error_logs | length > 0 %}
      apache_error_logs:
        type: file
        file_key: "file_path"
        include: {{ error_logs }}
{%- endif %}
{%- if logfmt_logs | length > 0 %}
      apache_logfmt_logs:
        type: file
        file_key: "file_path"
        include: {{ logfmt_logs }}
{%- endif %}
{%- if json_logs | length > 0 %}
      apache_json_logs:
        type: file
        file_key: "file_path"
        include: {{ json_logs }}
{%- endif %}
{%- endmacro %}

{%- macro apache_logs_transforms(common_logs=[], combined_logs=['/var/log/apache2/access_log'], error_logs=['/var/log/apache2/error_log'], logfmt_logs=[], json_logs=[]) %}
{%- if common_logs | length > 0 %}
      parsed_apache_access_logs_common:
        type: remap
        inputs:
          - apache_access_logs_common
        source: |-
          . = merge(., parse_apache_log!(.message, format: "common"))
{%- endif %}
{%- if combined_logs | length > 0 %}
      parsed_apache_access_logs_combined:
        type: remap
        inputs:
          - apache_access_logs_combined
        source: |-
          . = merge(., parse_apache_log!(.message, format: "combined"))
{%- endif %}
{%- if error_logs | length > 0 %}
      parsed_apache_error_logs:
        type: remap
        inputs:
          - apache_error_logs
        source: |-
          parsed, err = parse_apache_log(.message, format: "error", timestamp_format: "%a %b %d %T%.6f %Y")
          if err == null {
            . = merge(., parsed)
          }
{%- endif %}
{%- if logfmt_logs | length > 0 %}
      parsed_apache_access_logs_logfmt:
        type: remap
        inputs:
          - apache_access_logs_logfmt
        source: |-
          . = merge(., parse_logfmt!(.message))
{%- endif %}
{%- if json_logs | length > 0 %}
      parsed_apache_access_logs_json:
        type: remap
        inputs:
          - apache_access_logs_json
        source: |-
          . = merge(., parse_json!(.message))
{%- endif %}
{%- endmacro %}
