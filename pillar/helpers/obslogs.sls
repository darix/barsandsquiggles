{%- macro obs_logs_sources(rails_logs=['/srv/www/obs/api/log/production.log']) %}
{%- if rails_logs | length > 0 %}
      obs_rails_logs:
        type: file
        file_key: "file_path"
        include: {{ rails_logs }}
        multiline:
          start_pattern: '^[DIWEFA], \['
          condition_pattern: '^[DIWEFA], \['
          mode: halt_before
          timeout_ms: 1000
{%- endif %}
{%- endmacro %}

{%- macro obs_logs_transforms(rails_logs=['/srv/www/obs/api/log/production.log']) %}
{%- if rails_logs | length > 0 %}
      parsed_obs_rails_logs:
        type: remap
        inputs:
          - obs_rails_logs
{%- raw %}
# Expects the production format of the OBS frontend (Logger::Formatter, log_tags [:request_id], lograge key=value):
# I, [2026-01-01T12:00:00.123456 #1234]  INFO -- : [<request_id>] method=GET path=/about format=xml controller=AboutController action=index status=200 ... params={} host=127.0.0.1 backend=0.00 user=_nobody_ bot=false
# ActiveJob and Backend::Connection add their own tags in front of the request/job id.
# host from lograge (the client address) is stored as client_ip, to keep vector's host field.
{%- endraw %}
        source: |-
          parsed, err = parse_regex(.message, r'(?s)\A(?P<severity_letter>[DIWEFA]), \[(?P<log_timestamp>[^\] ]+) #(?P<pid>\d+)\]\s+(?P<severity>\w+) -- (?P<progname>[^:]*): (?:(?P<tags>(?:\[[^\]]*\] )*)\[(?P<request_id>[^\]]+)\] )?(?P<message>.*)')
          if err == null {
            . = merge(., parsed)
            .tags = map_values(parse_regex_all(string(.tags) ?? "", r'\[(?P<tag>[^\]]*)\]') ?? []) -> |tag| { tag.tag }
            .timestamp = parse_timestamp(string(.log_timestamp) ?? "", format: "%Y-%m-%dT%H:%M:%S%.6f") ?? .timestamp
            del(.log_timestamp)
            if match(string(.message) ?? "", r'\Amethod=\S+ path=\S+ ') {
              . = merge(., parse_regex(.message, r'\Amethod=(?P<method>\S+) path=(?P<path>\S+) ') ?? {})
              . = merge(., parse_regex(.message, r' format=(?P<format>\S+)') ?? {})
              . = merge(., parse_regex(.message, r' controller=(?P<controller>\S+)') ?? {})
              . = merge(., parse_regex(.message, r' action=(?P<action>\S+)') ?? {})
              . = merge(., parse_regex(.message, r' status=(?P<status>\d+)') ?? {})
              . = merge(., parse_regex(.message, r' duration=(?P<duration>[\d.]+)') ?? {})
              . = merge(., parse_regex(.message, r' view=(?P<view>[\d.]+)') ?? {})
              . = merge(., parse_regex(.message, r' db=(?P<db>[\d.]+)') ?? {})
              . = merge(., parse_regex(.message, r' params=(?P<params>\{.*\}) host=') ?? {})
              . = merge(., parse_regex(.message, r'.* host=(?P<client_ip>\S*)') ?? {})
              . = merge(., parse_regex(.message, r'.* backend=(?P<backend>[\d.]+)') ?? {})
              . = merge(., parse_regex(.message, r'.* user=(?P<user>\S*)') ?? {})
              . = merge(., parse_regex(.message, r'.* bot=(?P<bot>true|false)') ?? {})
              . = merge(., parse_regex(.message, r' error=\x27(?P<error>.*?)\x27(?: \w+=|\z)') ?? {})
              .status = to_int(.status) ?? .status
              .duration = to_float(.duration) ?? .duration
              .view = to_float(.view) ?? .view
              .db = to_float(.db) ?? .db
              .backend = to_float(.backend) ?? .backend
              .bot = to_bool(.bot) ?? .bot
            }
          }
{%- endif %}
{%- endmacro %}
