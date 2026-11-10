{%- set loki_data_dir = "/var/lib/loki"       %}

loki:
  config:
    ruler:
      storage:
        type: local
        local:
          directory: {{ loki_data_dir }}/rules
