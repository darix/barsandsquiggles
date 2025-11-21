#!py
#
# thepostman
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

class GrafanaAppService:
  def __init__(self,config):
    self.appname = None
    self.package_list = []
    self.config_dir   = None
    self.service_name = None
    self.config = config
    self.default_config_filename = "config"

    self.service_deps = []

  def build_config(self):
    self.package_section = f"{self.appname}_packages"
    self.config_section = f"{self.appname}_config"
    self.service_section = f"{self.appname}_service"
    self.target_section = f"{self.appname}_target"

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
            {'dataset':         instance_config},
            {'serializer':      'yaml'},
            {'serializer_opts': {'indent': 2}}
          ]
        }

        self.config[service_section] = {
          "service.running": [
            {"name":    f"{self.service_name}@{instance_name}.service" },
            {"enable":  True},
            {"reload":  True},
            {"require": service_deps}
            {"require_in": self.target_section}
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
            {'dataset':         __salt__['pillar.get'](f"{self.appname}:config", {})},
            {'serializer':      'yaml'},
            {'serializer_opts': {'indent': 2}}
          ]
        }

        self.config[service_section] = {
          "service.running": [
            {"name":    f"{self.service_name}.service" },
            {"enable":  True},
            {"reload":  True},
            {"require": self.service_deps}
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
      self.config[self.service_section] = {
        "service.dead": [
            {'name': self.service_name},
            {'enable': False},
            {'require': self.target_section},
        ]
      }

      self.config[self.config_section] = {
        "file.absent": [
          {'name':    f"{self.config_dir}/{self.default_config_filename}.yaml" },
          {'require': [self.service_section]},
        ]
      }
      purge_deps.append(self.config_section)

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
    self.build_config()

class MimirService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "mimir"
    self.package_list = ["mimir"]
    self.config_dir = "/etc/mimir"
    self.service_name = "mimir"
    self.build_config()

class LokiService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "loki"
    self.package_list = ["logcli", "loki", "lokitool", "promtail"]
    self.config_dir = "/etc/loki"
    self.service_name = "loki"
    self.default_config_filename = "loki"
    self.build_config()

class GrafanaService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "grafana"
    self.package_list = ["grafana"]
    self.config_dir = "/etc/grafana"
    self.service_name = "grafana-server"
    self.build_config()

  def setup_config_section(self):
    self.service_deps.append(self.config_section)
    requires = [self.package_section]
    self.config[self.config_section] = {
      'file.serialize': [
        {'name':            f"{self.config_dir}/{self.default_config_filename}.yaml"},
        {'user':            'root'},
        {'group':           self.appname},
        {'mode':            '0640'},
        {'require':         requires },
        {'dataset':         __salt__['pillar.get'](f"{self.appname}:config", {})},
        {'serializer':      'yaml'},
        {'serializer_opts': {'indent': 2}}
      ]
    }

def run():
  config = {}

  LokiService(config)
  TempoService(config)
  MimirService(config)
  GrafanaService(config)

  return config