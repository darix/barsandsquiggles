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

vector:
  require:
    - step_client_host_generic_acl_0
    - step_client_user_generic_acl_0
