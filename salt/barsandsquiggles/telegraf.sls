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

import os.path

def run():
  config = {}

  telegraf_packages     = ['telegraf']
  telegraf_snippets_dir   = '/etc/telegraf/telegraf.d'
  telegraf_config_path  = '/etc/telegraf/telegraf.conf'
  telegraf_service_name = 'telegraf.service'

  if __salt__['pillar.get']('telegraf:enabled', False):
    config['telegraf_packages'] = {
      'pkg.installed': [
        {'pkgs': telegraf_packages},
      ]
    }

    config['telegraf_snippets_dir'] = {
      'file.directory': [
        {'name': telegraf_snippets_dir},
        {'user': 'root'},
        {'group': 'root'},
        {'mode':  '0755'},
        {'require': ['telegraf_packages']},
      ]
    }

    config['telegraf_config'] = {
      'file.serialize': [
        {'name': telegraf_config_path},
        {'user': 'root'},
        {'group': 'root'},
        {'mode':  '0644'},
        {'require': ['telegraf_packages', 'telegraf_snippets_dir']},
        {'dataset_pillar':  'telegraf:config'},
        {'serializer': 'toml'},
        {'serializer_opts': {'indent': 2}},
      ]
    }

    if os.path.exists(telegraf_snippets_dir):
      for filename in os.listdir(telegraf_snippets_dir):
        full_path = os.path.join(telegraf_snippets_dir, filename)
        config_section = f"telegraf_purge_unmanaged_snippet_{filename}"
        config[config_section] = {
            'file.absent': [
              {'name': full_path },
              {'require_in': ['telegraf_service']},
              {'require':    ['telegraf_packages']},
            ]
          }

    config['telegraf_service'] = {
      'service.running': [
        {'name': telegraf_service_name},
        {'enable': True},
        {'require': ['telegraf_config']},
      ]
    }

  else:
    config['telegraf_service'] = {
      'service.dead': [
        {'name': telegraf_service_name},
        {'enable': False},
      ]
    }
    config['telegraf_config'] = {
      'file.absent': [
        {'name': telegraf_config_path },
        {'require': ['telegraf_service']}
      ]
    }
    config['telegraf_packages'] = {
      'pkg.removed': [
        {'pkgs': telegraf_packages},
        {'require': ['telegraf_config']}
      ]
    }

  return config
