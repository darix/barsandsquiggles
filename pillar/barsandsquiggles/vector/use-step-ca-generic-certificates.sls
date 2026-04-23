step:
  certificates:
    host:
      generic:
        acls_for_combined_file:
          - acl_type: user
            acl_names:
            - vector
        affected_services:
            - vector.service
    user:
      generic:
        acls_for_combined_file:
          - acl_type: user
            acl_names:
            - vector
        affected_services:
            - vector.service

loki:
  tls:
    server:
      cert_file: /etc/step/certs/generic.host.full.pem
      key_file:  /etc/step/certs/generic.host.full.pem
      client_auth_type: RequireAndVerifyClientCert
    client:
      tls_cert_path: /etc/step/certs/generic.user.full.pem
      tls_key_path:  /etc/step/certs/generic.user.full.pem
