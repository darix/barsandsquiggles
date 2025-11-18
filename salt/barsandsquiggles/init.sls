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
    self.appname = ""
    self.package_list = []
    self.config_path = ""
    self.service_name = ""
    self.config = config

    self.service_deps = []

  def build_config(self):
    self.package_section = f"{self.appname}_packages"
    self.config_section = f"{self.appname}_config"
    self.service_section = f"{self.appname}_service"

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

    self.config[self.service_section] = {
      "service.running": [
        {"name":    self.service_name},
        {"enable":  True},
        {"reload":  True},
        {"require": self.service_deps}
      ]
    }

  def setup_config_section(self):
    self.service_deps.append(self.config_section)
    requires = [self.package_section]
    self.config[self.config_section] = {
      'file.serialize': [
        {'name':            self.config_path},
        {'user':            'root'},
        {'group':           self.appname},
        {'mode':            '0640'},
        {'require':         requires },
        {'dataset':         __salt__['pillar.get'](f"{self.appname}:config", {})},
        {'serializer':      'yaml'},
        {'serializer_opts': {'indent': 2}}
      ]
    }

  def cleanup_sections(self):
    self.config[self.service_section] = {
      "service.dead": [
          {'name': self.service_name},
          {'enable': False},
      ]
    }

    self.config[self.config_section] = {
      "file.absent": [
        {'name':    self.config_path },
        {'require': [self.service_section]},
      ]
    }

    self.config[self.package_section] = {
      "pkg.purged": [
        {'pkgs':    self.package_list},
        {'require': [self.config_section]},
      ]
    }

class TempoService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "tempo"
    self.package_list = ["tempo"]
    self.config_path = "/etc/tempo/config.yaml"
    self.service_name = "tempo.service"
    self.build_config()

class MimirService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "mimir"
    self.package_list = ["mimir"]
    self.config_path = "/etc/mimir/config.yaml"
    self.service_name = "mimir.service"
    self.build_config()

class LokiService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "loki"
    self.package_list = ["logcli", "loki", "lokitool", "promtail"]
    self.config_path = "/etc/loki/loki.yaml"
    self.service_name = "loki.service"
    self.build_config()

class GrafanaService(GrafanaAppService):
  def __init__(self, config):
    super().__init__(config)
    self.appname = "grafana"
    self.package_list = ["grafana"]
    self.config_path = "/etc/grafana/grafana.yaml"
    self.service_name = "grafana-server.service"
    self.build_config()

  def setup_config_section(self):
    self.service_deps.append(self.config_section)
    requires = [self.package_section]
    self.config[self.config_section] = {
      'file.serialize': [
        {'name':            self.config_path},
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