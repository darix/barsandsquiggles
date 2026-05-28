{%- set global_non_proxy_protocol_http_listen_port=3000 %}
{%-     set global_proxy_protocol_http_listen_port=3002 %}
{%- set global_non_proxy_protocol_grpc_listen_port=3001 %}
{%-     set global_proxy_protocol_grpc_listen_port=3003 %}
{%- set global_bind_ips = ['0.0.0.0'] %}

{%- macro haproxy_loki_listen_by_protocol(mine_target, mine_function, target_port, protocol_name, proxy_protocol_listen_port, non_proxy_protocol_listen_port, bind_ips=global_bind_ips) %}
    loki_listen_{{ protocol_name }}:
      mode: tcp
      options:
      - tcplog
      - tcpka
      bind:
      {%- for bind_ip in bind_ips %}
      - '{{ bind_ip }}:{{ non_proxy_protocol_listen_port }} tfo'
      - '{{ bind_ip }}:{{ proxy_protocol_listen_port }} tfo accept-proxy'
      {%- endfor %}
      timeouts:
        client: 150m
        server: 150m
      {%- if protocol_name == "http" %}
      httprequests:
        - 'set-header Upgrade %[req.hdr(Upgrade)]'
        - 'set-header Connection upgrade'
      {%- endif %}
      servers:
        # for each node matching the target it will count up the loop index and append that to the server name
        loki-{{ protocol_name }}:
          mine_target:    {{ mine_target   }}
          mine_functions: {{ mine_function }}
          # starting weight
          mine_max_weight: 90
          # if this option is false then all nodes get the same weight value from mine_max_weight
          mine_scale_weight: true
          # optionally set backup for all nodes with weight < mine_max_weight - only makes sense in combination with enabling mine_scale_weight
          mine_setbackup: true
          port: {{ target_port}}
          extra: send-proxy-v2
{%- endmacro %}


{%- macro haproxy_loki_http_listen(mine_target, mine_function, target_port=global_non_proxy_protocol_http_listen_port, proxy_protocol_listen_port=global_proxy_protocol_http_listen_port, non_proxy_protocol_listen_port=global_non_proxy_protocol_http_listen_port, bind_ips=global_bind_ips) %}
{{ haproxy_loki_listen_by_protocol(mine_target=mine_target, mine_function=mine_function, target_port=target_port, protocol_name="http", proxy_protocol_listen_port=proxy_protocol_listen_port, non_proxy_protocol_listen_port=non_proxy_protocol_listen_port, bind_ips=bind_ips) }}
{%- endmacro %}

{%- macro haproxy_loki_grpc_listen(mine_target, mine_function, target_port=global_non_proxy_protocol_grpc_listen_port, proxy_protocol_listen_port=global_proxy_protocol_grpc_listen_port, non_proxy_protocol_listen_port=global_non_proxy_protocol_grpc_listen_port, bind_ips=global_bind_ips) %}
{{ haproxy_loki_listen_by_protocol(mine_target=mine_target, mine_function=mine_function, target_port=target_port, protocol_name="grpc", proxy_protocol_listen_port=proxy_protocol_listen_port, non_proxy_protocol_listen_port=non_proxy_protocol_listen_port, bind_ips=bind_ips) }}
{%- endmacro %}

{%- macro haproxy_loki_listen(mine_target, mine_function, proxy_protocol_http_listen_port=global_proxy_protocol_http_listen_port, non_proxy_protocol_http_listen_port=global_non_proxy_protocol_http_listen_port, proxy_protocol_grpc_listen_port=global_proxy_protocol_grpc_listen_port, non_proxy_protocol_grpc_listen_port=global_non_proxy_protocol_grpc_listen_port, bind_ips=global_bind_ips) %}
{{ haproxy_loki_http_listen(mine_target=mine_target, mine_function=mine_function, proxy_protocol_listen_port=proxy_protocol_http_listen_port, non_proxy_protocol_listen_port=non_proxy_protocol_http_listen_port, bind_ips=bind_ips) }}
{{ haproxy_loki_grpc_listen(mine_target=mine_target, mine_function=mine_function, proxy_protocol_listen_port=proxy_protocol_grpc_listen_port, non_proxy_protocol_listen_port=non_proxy_protocol_grpc_listen_port, bind_ips=bind_ips) }}
{%- endmacro %}
