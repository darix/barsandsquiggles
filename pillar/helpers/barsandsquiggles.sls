{%- macro vector_loki_sink_tls_client_cert(loki_server, server_cert = "/etc/step/certs/generic.host.full.pem", client_cert = "/etc/step/certs/generic.user.full.pem" ) %}
        type: "loki"
        endpoint: "{{ loki_server }}"
        compression: gzip
        encoding:
          codec: "json"
          json:
            pretty: true
        out_of_order_action: "accept"
        healthcheck:
          enabled: true
        tls:
          crt_file: {{ client_cert }}
          key_file: {{ client_cert }}
{%- endmacro %}