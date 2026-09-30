{%- macro apache_logs_sources(common_logs=[], combined_logs=['/var/log/apache2/access_log'], error_logs=['/var/log/apache2/error_log']) %}
{%- if len(common_logs) > 0 %}
      apache_access_logs_common:
        type: file
        file_key: "file_path"
        include: {{ common_logs }}
{%- endif %}
{%- if len(combined_logs) > 0 %}
      apache_access_logs_combined:
        type: file
        file_key: "file_path"
        include: {{ combined_logs }}
{%- endif %}
{%- if len(error_logs) > 0 %}
      apache_error_logs:
        type: file
        file_key: "file_path"
        include: {{ error_logs }}
{%- endif %}
{%- endmacro %}

{%- macro apache_logs_transforms(common_logs=[], combined_logs=['/var/log/apache2/access_log'], error_logs=['/var/log/apache2/error_log']) %}
{%- if len(common_logs) > 0 %}
      parsed_apache_access_logs_common:
        type: remap
        inputs:
          - apache_access_logs_common
        source: |-
          . = merge(., parse_apache_log!(.message, format: "common"))
{%- endif %}
{%- if len(combined_logs) > 0 %}
      parsed_apache_access_logs_combined:
        type: remap
        inputs:
          - apache_access_logs_combined
        source: |-
          . = merge(., parse_apache_log!(.message, format: "combined"))
{%- endif %}
{%- if len(error_logs) > 0 %}
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
{%- endmacro %}
