#!py
#
# barsandsquiggles
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
from salt.utils.user import get_group_list

import copy
import salt.utils.dictupdate as dictupdate

def deepmerge(current_config, additional_config):
    return dictupdate.update(copy.deepcopy(current_config), copy.deepcopy(additional_config), merge_lists=True)

def run():
  config = {}

  if __salt__['pillar.get']('vector:enabled', True):
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

    config_format = __salt__['pillar.get']('vector:config_format', "yaml")
    valid_config_formats = ['yaml', 'toml', 'json']

    if not(config_format in valid_config_formats):
      raise SaltRenderError(f"The format {config_format} is not valid! only json/toml/yaml are allowed.")

    unused_config_formats = valid_config_formats.copy()
    unused_config_formats.remove(config_format)

    config_filename = f'/etc/vector/vector.{config_format}'

    vector_config_dict      = __salt__['pillar.get']('vector:config', {})
    vector_endpoint_configs = __salt__['pillar.get']('vector:endpoints', {})

    if len(vector_endpoint_configs) > 0:
      for sink_label, sink_data in vector_config_dict.get('sinks', {}).items():
        new_config = sink_data

        for config_key in ['type', 'endpoint_config']:
          if config_key in sink_data:
            endpoint_config = vector_endpoint_configs.get(sink_data.get(config_key), {})
            if len(endpoint_config) > 0:
              new_config = deepmerge(endpoint_config, new_config)

        if 'endpoint_config' in new_config:
          a.pop('endpoint_config')

        vector_config_dict['sinks'][sink_label] = new_config

    config['vector_config'] = {
      'file.serialize': [
        {'name':            config_filename},
        {'user':            'root'},
        {'group':           'vector'},
        {'mode':            '0640'},
        {'require':         ['vector_packages'] },
        {'dataset':         vector_config_dict},
        {'serializer':      config_format},
        {'serializer_opts': {'indent': 2}},
      ]
    }

    for unused_config_format in unused_config_formats:
      config[f'cleanup_vector_unused_config_{unused_config_format}'] = {
        'file.absent': [
          {'name': f'/etc/vector/vector.{unused_config_format}'},
          {'require_in': ['vector_service']},
        ]
      }

    vector_defaults = __salt__['pillar.get']('vector:environment', [])
    vector_defaults.append(f"VECTOR_CONFIG_{config_format.upper()}={config_filename}")

    config['vector_defaults'] = {
      "file.managed": [
        {'name':     '/etc/default/vector'},
        {'user':     'root'},
        {'group':    'root'},
        {'mode':     '0640'},
        {'require':  ['vector_packages'] },
        {'contents': "\n".join(vector_defaults)},
      ]
    }

    vector_service_requires = ['vector_config', 'vector_defaults']
    vector_service_watch    = ['vector_config', 'vector_defaults']

    vector_additional_groups = __salt__['pillar.get']('vector:additional_groups', [])
    if len(vector_additional_groups) > 0:
      vector_groups = get_group_list("vector")
      vector_groups.extend(vector_additional_groups)
      vector_groups = list(set(vector_groups))

      config['vector_additional_groups'] = {
        "user.present": [
          {'name':       'vector'},
          {'groups':     vector_groups},
          {'require':    ['vector_config']},
          {'require_in': ['vector_service']},
          {'watch_in': ['vector_service']},
        ]
      }
      vector_service_watch.append('vector_additional_groups')
      vector_service_requires.append('vector_additional_groups')

    additional_requires = __salt__['pillar.get']('vector:requires', [])
    if len(additional_requires) > 0:
      vector_service_requires.extend(additional_requires)
      vector_service_requires = list(set(vector_service_requires))

    vector_service_name = 'vector.service'

    if __salt__['pillar.get']('vector:use_hardened_service', False):
      vector_service_name = 'hardened-vector.service'

    config['vector_service'] = {
      'service.running': [
        {'name':    vector_service_name},
        # reload is disabled because new sinks/sources arent enabled
        # {'reload':  True},
        {'enable':  True},
        {'require': vector_service_requires},
        {'watch':   vector_service_watch},
      ]
    }

  return config
