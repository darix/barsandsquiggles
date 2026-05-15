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

    config['vector_config'] = {
      'file.serialize': [
        {'name':            config_filename},
        {'user':            'root'},
        {'group':           'vector'},
        {'mode':            '0640'},
        {'require':         ['vector_packages'] },
        {'dataset_pillar':  'vector:config'},
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

    vector_additional_groups = __salt__['pillar.get']('vector:additional_groups', [])
    if len(vector_additional_groups) > 0:
      vector_groups = get_group_list("vector")
      vector_groups.extend(vector_additional_groups)
      vector_groups = list(set(vector_groups))

      config['vector_additional_groups'] = {
        "user.present": [
          {'name':       'vector'},
          {'groups':     vector_groups},
          {'require_in': ['vector_service']},
        ]
      }

    vector_service_requires = ['vector_config', 'vector_defaults']
    vector_service_watch    = ['vector_config', 'vector_defaults']

    additional_requires = __salt__['pillar.get']('vector:requires', [])
    if len(additional_requires) > 0:
      vector_service_requires.extend(additional_requires)
      vector_service_requires = list(set(vector_service_requires))

    config['vector_service'] = {
      'service.running': [
        {'name':    'vector.service'},
        {'reload':  True},
        {'enable':  True},
        {'require': vector_service_requires},
        {'watch':   vector_service_watch},
      ]
    }

  return config