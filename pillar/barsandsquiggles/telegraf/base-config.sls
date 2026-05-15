#!toml

[telegraf]
enabled = false
[telegraf.config.agent]
collection_jitter = "0s"
flush_interval = "10s"
flush_jitter = "0s"
interval = "10s"
metric_batch_size = 1000
metric_buffer_limit = 10000
precision = "0s"
round_interval = true
[telegraf.config.global_tags]
[[telegraf.config.inputs.cpu]]
collect_cpu_time = false
core_tags = false
percpu = true
report_active = false
totalcpu = true
[[telegraf.config.inputs.disk]]
ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
[[telegraf.config.inputs.diskio]]
[[telegraf.config.inputs.kernel]]
[[telegraf.config.inputs.mem]]
[[telegraf.config.inputs.processes]]
[[telegraf.config.inputs.swap]]
[[telegraf.config.inputs.system]]
