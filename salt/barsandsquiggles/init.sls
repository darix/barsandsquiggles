#!py
#
# barsandsquiggles
#
# Copyright (C) 2025   darix
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
import copy
import salt.utils.dictupdate as dictupdate
import logging

log = logging.getLogger("barsandsquiggles")

class GrafanaAppService:
  def __init__(self,config):
    self.appname = None
    self.package_list = []
    self.config_dir   = None
    self.service_name = None
    self.config = config
    self.default_config_filename = "config"

    self.service_deps = []

  def setup_names(self):
    self.package_section = f"{self.appname}_packages"
    self.config_section = f"{self.appname}_config"
    self.service_section = f"{self.appname}_service"
    self.target_section = f"{self.appname}_target"

  def build_config(self):
    if self.appname in __pillar__ and __pillar__[self.appname].get("enabled", True):
      self.setup_sections()
    else:
      self.cleanup_sections()

  def setup_sections(self):
    self.config[self.package_section] = {
      "pkg.installed": [
        { "pkgs": self.package_list },
      ]
    }

    self.setup_config_section()

  def merge_in_ssl_settings(self, config_block):
    return {}


  def setup_config_section(self):
    requires = [self.package_section]

    if "instances" in __salt__['pillar.get'](f"{self.appname}"):
      for instance_name, instance_config in __salt__['pillar.get'](f"{self.appname}:instances", {}).items():

        service_section = f"{self.service_section}_{instance_name}"
        config_section = f"{self.config_section}_{instance_name}"
        config_path    = f"{self.config_dir}/{instance_name}.yaml"

        service_deps = self.service_deps.copy()
        service_deps.append(config_section)

        self.config[config_section] = {
          'file.serialize': [
            {'name':            config_path},
            {'user':            'root'},
            {'group':           self.appname},
            {'mode':            '0640'},
            {'require':         requires },
            {'dataset':         self.merge_in_ssl_settings(instance_config)},
            {'serializer':      'yaml'},
            {'serializer_opts': {'indent': 2}},
          ]
        }

        self.config[service_section] = {
          "service.running": [
            {"name":    f"{self.service_name}@{instance_name}.service" },
            {"enable":  True},
            {"reload":  True},
            {"require": service_deps},
            {"watch":   service_deps},
            {"require_in": self.target_section},
          ]
        }

      self.config[self.target_section] = {
        "service.running": [
          {"name":    f"{self.service_name}.target" },
          {"enable":  True},
          {"reload":  True},
        ]
      }
    else:
        service_section = f"{self.service_section}"
        config_section = f"{self.config_section}"
        config_path    = f"{self.config_dir}/{self.default_config_filename}.yaml"

        service_deps = self.service_deps.copy()
        service_deps.append(config_section)

        self.config[config_section] = {
          'file.serialize': [
            {'name':            config_path},
            {'user':            'root'},
            {'group':           self.appname},
            {'mode':            '0640'},
            {'require':         requires },
            {'dataset':         self.merge_in_ssl_settings(__salt__['pillar.get'](f"{self.appname}:config", {}))},
            {'serializer':      'yaml'},
            {'serializer_opts': {'indent': 2}},
          ]
        }

        self.config[service_section] = {
          "service.running": [
            {"name":    f"{self.service_name}.service" },
            {"enable":  True},
            {"reload":  True},
            {"require": self.service_deps},
            {"watch":   self.service_deps},
          ]
        }

  def cleanup_sections(self):
    purge_deps = [self.service_section]
    self.config[self.target_section] = {
      "service.dead": [
          {'name': f"{self.service_name}.target"},
          {'enable': False},
      ]
    }

    if "instances" in __salt__['pillar.get'](f"{self.appname}"):
      for instance_name, instance_config in __salt__['pillar.get'](f"{self.appname}:instances", {}).items():
        service_section = f"{self.service_section}_{instance_name}"
        config_section = f"{self.config_section}_{instance_name}"
        config_path    = f"{self.config_dir}/{instance_name}.yaml"

      self.config[service_section] = {
        "service.dead": [
            {'name': f"{self.service_name}@{instance_name}.service"},
            {'enable': False},
            {'require': self.target_section},
        ]
      }

      self.config[config_section] = {
        "file.absent": [
          {'name':    config_path },
          {'require': [service_section]},
        ]
      }
      purge_deps.append(config_section)
    else:
      purge_deps.append(self.service_section)
      self.config[self.service_section] = {
        "service.dead": [
            {'name': self.service_name},
            {'enable': False},
            {'require': [self.target_section]}
        ]
      }

      purge_deps.append(self.config_section)
      self.config[self.config_section] = {
        "file.absent": [
          {'name':    f"{self.config_dir}/{self.default_config_filename}.yaml" },
          {'require': [self.service_section]},
        ]
      }

    self.config[self.package_section] = {
      "pkg.purged": [
        {'pkgs':    self.package_list},
        {'require': purge_deps},
      ]
    }

class TempoService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "tempo"
    self.package_list = ["tempo"]
    self.config_dir = "/etc/tempo"
    self.service_name = "tempo"
    self.setup_names()
    self.build_config()

class MimirService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "mimir"
    self.package_list = ["mimir"]
    self.config_dir = "/etc/mimir"
    self.service_name = "mimir"
    self.setup_names()
    self.build_config()
    # TODO: needs the runtime config

class LokiService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "loki"
    self.package_list = ["logcli", "loki", "lokitool",]
    self.config_dir = "/etc/loki"
    self.service_name = "loki"
    self.default_config_filename = "loki"
    self.setup_names()
    self.build_config()

  def merge_in_ssl_settings(self, config_block):
    ssl_config = {}
    ssl_server = __salt__['pillar.get'](f"{self.appname}:tls:server", {})
    ssl_client = __salt__['pillar.get'](f"{self.appname}:tls:client", {})
    # log.error(f"server:{ssl_server} client:{ssl_client}")

    ca_file           = __salt__['pillar.get'](f"{self.appname}:tls:ca_path", None)
    tls_min_version   = __salt__['pillar.get'](f"{self.appname}:tls:tls_min_version",   "VersionTLS13")
    tls_cipher_suites = __salt__['pillar.get'](f"{self.appname}:tls:tls_cipher_suites", "TLS_CHACHA20_POLY1305_SHA256")

    if not("client_ca_file" in ssl_server):
      ssl_server["client_ca_file"] = ca_file

    if len(ssl_server) > 0:
      ssl_config["server"] = {
        "http_tls_config": ssl_server,
        "grpc_tls_config": ssl_server,
        "tls_min_version": tls_min_version,
        "tls_cipher_suites": tls_cipher_suites,
      }

    if len(ssl_client) > 0:
      if not("tls_server_name" in ssl_client):
        ssl_client["tls_server_name"] = __salt__['pillar.get'](f"{self.appname}:tls:tls_hostname", __salt__['grains.get']("id"))

      if not("tls_ca_path" in ssl_client) and not(ca_file is None):
        ssl_client["tls_ca_path"] = ca_file

      if not("tls_cipher_suites" in ssl_client):
        ssl_client["tls_cipher_suites"] = tls_cipher_suites

      if not("tls_min_version" in ssl_client):
        ssl_client["tls_min_version"] = tls_min_version

      grpc_client_ssl_config = ssl_client.copy()
      grpc_client_ssl_config["tls_enabled"] = True

      grpc_client_config_sections = [
        "ingester_client",
        "query_scheduler",
        "frontend",
        "frontend_worker",
      ]

      for section in grpc_client_config_sections:
        ssl_config[section] = { "grpc_client_config": grpc_client_ssl_config }

      ssl_config["memberlist"] = grpc_client_ssl_config

      ssl_config["frontend"]["tail_tls_config"] = ssl_client
      ssl_config["storage_config"] = {
        "tsdb_shipper": {
          "index_gateway_client": {
            "grpc_client_config": grpc_client_ssl_config
          }
        }
      }
      ssl_config["ruler"] = {
        "ruler_client": grpc_client_ssl_config,
        "evaluation": {
          "query_frontend": grpc_client_ssl_config
        }
      }

    if len(ssl_config) > 0:
      return dictupdate.update(copy.deepcopy(config_block), ssl_config, recursive_update=True, merge_lists=True)
    else:
      return config_block

class GrafanaService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "grafana"
    self.package_list = ["grafana"]
    self.config_dir = "/etc/grafana"
    self.service_name = "grafana-server"
    self.setup_names()
    self.build_config()

  def setup_config_section(self):
    requires = [self.package_section]
    self.config[self.config_section] = {
      'file.serialize': [
        {'name':       f"{self.config_dir}/grafana.ini"},
        {'user':       'root'},
        {'group':      self.appname},
        {'mode':       '0640'},
        {'require':    requires},
        {'dataset':    __salt__['pillar.get'](f"{self.appname}:config", {})},
        {'serializer': 'configparser'},
      ]
    }

    watch_list = [self.config_section]

    datasources = __salt__['pillar.get'](f"{self.appname}:provisioning:datasources", {})
    for ds_name, ds_config in datasources.items():
      ds_section = f"{self.appname}_provisioning_datasource_{ds_name}"
      self.config[ds_section] = {
        'file.serialize': [
          {'name':            f"{self.config_dir}/provisioning/datasources/{ds_name}.yaml"},
          {'user':            'root'},
          {'group':           self.appname},
          {'mode':            '0640'},
          {'require':         [self.package_section]},
          {'dataset':         ds_config},
          {'serializer':      'yaml'},
          {'serializer_opts': {'indent': 2}},
        ]
      }
      watch_list.append(ds_section)

    dashboards = __salt__['pillar.get'](f"{self.appname}:provisioning:dashboards", {})
    for db_name, db_data in dashboards.items():
      db_config_section = f"{self.appname}_provisioning_dashboard_{db_name}_config"
      self.config[db_config_section] = {
        'file.serialize': [
          {'name':            f"{self.config_dir}/provisioning/dashboards/{db_name}.yaml"},
          {'user':            'root'},
          {'group':           self.appname},
          {'mode':            '0640'},
          {'require':         [self.package_section]},
          {'dataset':         db_data.get('config', {})},
          {'serializer':      'yaml'},
          {'serializer_opts': {'indent': 2}},
        ]
      }
      watch_list.append(db_config_section)

      for file_name, file_source in db_data.get('files', {}).items():
        db_file_section = f"{self.appname}_provisioning_dashboard_{db_name}_file_{file_name}"
        self.config[db_file_section] = {
          'file.managed': [
            {'name':     f"/var/lib/grafana/dashboards/{file_name}"},
            {'source':   file_source},
            {'user':     'root'},
            {'group':    self.appname},
            {'mode':     '0640'},
            {'makedirs': True},
            {'require':  [self.package_section]},
          ]
        }
        watch_list.append(db_file_section)

    plugins = __salt__['pillar.get'](f"{self.appname}:plugins", [])
    for plugin_name in plugins:
      plugin_section = f"{self.appname}_plugin_{plugin_name}"
      self.config[plugin_section] = {
        "cmd.run": [
          {"name":    f"grafana-cli plugins install {plugin_name}"},
          {"unless":  f"grafana-cli plugins ls | grep '{plugin_name}'"},
          {"require": [self.package_section]},
        ]
      }
      watch_list.append(plugin_section)

    self.config[self.service_section] = {
      "service.running": [
        {"name":   f"{self.service_name}.service"},
        {"enable": True},
        {"watch":  watch_list},
      ]
    }

  def cleanup_sections(self):
    self.config[self.target_section] = {
      "service.dead": [
        {'name':   f"{self.service_name}.target"},
        {'enable': False},
      ]
    }

    self.config[self.service_section] = {
      "service.dead": [
        {'name':    self.service_name},
        {'enable':  False},
        {'require': [self.target_section]},
      ]
    }

    purge_deps = [self.service_section]

    self.config[self.config_section] = {
      "file.absent": [
        {'name':    f"{self.config_dir}/grafana.ini"},
        {'require': [self.service_section]},
      ]
    }
    purge_deps.append(self.config_section)

    datasources = __salt__['pillar.get'](f"{self.appname}:provisioning:datasources", {})
    for ds_name in datasources:
      ds_section = f"{self.appname}_provisioning_datasource_{ds_name}"
      self.config[ds_section] = {
        "file.absent": [
          {'name':    f"{self.config_dir}/provisioning/datasources/{ds_name}.yaml"},
          {'require': [self.service_section]},
        ]
      }
      purge_deps.append(ds_section)

    dashboards = __salt__['pillar.get'](f"{self.appname}:provisioning:dashboards", {})
    for db_name, db_data in dashboards.items():
      db_config_section = f"{self.appname}_provisioning_dashboard_{db_name}_config"
      self.config[db_config_section] = {
        "file.absent": [
          {'name':    f"{self.config_dir}/provisioning/dashboards/{db_name}.yaml"},
          {'require': [self.service_section]},
        ]
      }
      purge_deps.append(db_config_section)

      for file_name in db_data.get('files', {}):
        db_file_section = f"{self.appname}_provisioning_dashboard_{db_name}_file_{file_name}"
        self.config[db_file_section] = {
          "file.absent": [
            {'name':    f"/var/lib/grafana/dashboards/{file_name}"},
            {'require': [self.service_section]},
          ]
        }
        purge_deps.append(db_file_section)

    self.config[self.package_section] = {
      "pkg.purged": [
        {'pkgs':    self.package_list},
        {'require': purge_deps},
      ]
    }

def run():
  config = {}

  LokiService(config)
  TempoService(config)
  MimirService(config)
  GrafanaService(config)

  return config