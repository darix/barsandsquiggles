## This currently fails due to postgres:postgres u=rwX,go=
##

vector:
  additional_groups:
    - postgres
  config:
    sources:
      source_postgresql_json:
        type: file


    transforms:
      parsed_postgresql_json:
        type: remap
        inputs:
          - source_postgresql_json
        source: |-
          . = parse_json!(string!(.message))
