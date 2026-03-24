#!py
#
# thepostman
#
# Copyright (C) 2026   darix
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

from salt.exceptions import SaltRenderError


def run():
  config = {}

  if __salt__['pillar.get']('vector:enabled', False):
    vector_packages = ["vector"]

    if __salt__['pillar.get']('vector:enable_journal', False):
      vector_packages.append('vector-systemd')

    if __salt__['pillar.get']('vector:enable_remote_journal', False):
      vector_packages.append('vector-systemd-journal-remote')

    config['vector_packages'] = {
      'pkg.installed': [
        {'pkgs': vector_packages },
      ]
    }

    config_format = __salt__['pillar.get']( 'vector:config_format', "yaml")

    if not(config_format in ['yaml', 'toml', 'json']):
      raise SaltRenderError(f"The format {config_format} is not valid! only json/toml/yaml are allowed.")

    config['vector_config'] = {
      'file.serialize': [
        {'name':            f'/etc/vector/vector.{{ config_format }}'},
        {'user':            'root'},
        {'group':           'vector'},
        {'mode':            '0640'},
        {'require':         ['vector_packages'] },
        {'dataset_pillar':  'vector:config'},
        {'serializer':      config_format},
        {'serializer_opts': {'indent': 2}},
      ]
    }

    config['vector_service'] = {
      'service.running': [
        {'name':    'vector.service'},
        {'reload':  True},
        {'require': ['vector_config']},
        {'watch':   ['vector_config']},
      ]
    }

  return config