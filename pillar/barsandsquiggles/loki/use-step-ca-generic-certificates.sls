include:
  - includes.step-ca-use-generic-host-cert
  - includes.step-ca-use-generic-user-cert

step:
  certificates:
    host:
      generic:
        acls_for_combined_file:
          - acl_type: user
            acl_names:
            - loki
        affected_services:
            - loki.service
    user:
      generic:
        acls_for_combined_file:
          - acl_type: user
            acl_names:
            - loki
        affected_services:
            - loki.service

loki:
  require:
    - step_client_host_generic_acl_0
    - step_client_user_generic_acl_0
  tls:
    server:
      cert_file: /etc/step/certs/generic.host.full.pem
      key_file:  /etc/step/certs/generic.host.full.pem
      client_auth_type: RequireAndVerifyClientCert
    client:
      tls_cert_path: /etc/step/certs/generic.user.full.pem
      tls_key_path:  /etc/step/certs/generic.user.full.pem
