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
  alertmanager_packages = ['golang-github-prometheus-alertmanager']
  alertmanager_templates_dir = '/etc/prometheus/alertmanager_templates'
  alertmanager_config_path  = '/etc/prometheus/alertmanager.yml'
  alertmanager_service_name = 'prometheus-alertmanager.service'

  if __salt__['pillar.get']('alertmanager:use_matrix', False):
    alertmanager_packages.append('matrix-alertmanager-receiver')

  if __salt__['pillar.get']('alertmanager:enabled', False):
    config['alertmanager_packages'] = {
      'pkg.installed': [
        {'pkgs': alertmanager_packages},
      ]
    }
    config['alertmanager_config'] = {
      'file.serialize': [
        {'name': alertmanager_config_path},
        {'user': 'root'},
        {'group': 'root'},
        {'mode':  '0644'},
        {'require': ['alertmanager_packages']},
        {'dataset_pillar':  'alertmanager:config'},
        {'serializer': 'yaml'},
        {'serializer_opts': [{'indent': 2}]},
      ]
    }

    template_list = []
    alertmanager_template_prefix = 'alertmanager:templates'
    alertmanager_templates_data = __salt__['pillar.get'](alertmanager_template_prefix, {})
    if len(alertmanager_templates_data) > 0:
      names_data = []
      for template_name, template_data in alertmanager_templates_data.items():
        template_filename = f"{alertmanager_templates_dir}/{template_name}"
        template_list.append(template_filename)

        names_data.append({
          template_filename: [{'contents': template_data}]
        })
      config[f'alertmanager_templates'] = {
        'file.managed': [
          {'user': 'root'},
          {'group', 'root'},
          {'mode': '0644'},
          {'names': names_data},
          {'require_in': ['alertmanager_service']},
          {'watch_in':   ['alertmanager_service']},
          {'require':    ['alertmanager_packages']},
        ]
      }

    if os.path.exists(alertmanager_templates_dir):
      for filename in os.listdir(alertmanager_templates_dir):
        full_path = os.path.join(alertmanager_templates_dir, filename)
        if not(full_path in template_list):
          config_section = f"alertmanager_purge_unmanaged_template_{filename}"
          config[config_section] = {
              'file.absent': [
                {'name': full_path },
                {'require_in': ['alertmanager_service']},
                {'require':    ['alertmanager_packages']},
              ]
            }

    config['alertmanager_service'] = {
      'service.running': [
        {'name': alertmanager_service_name},
        {'enable': True},
        {'require': ['alertmanager_config']},
        {'watch':   ['alertmanager_config']}
      ]
    }
  else:
    config['alertmanager_service'] = {
      'service.dead': [
        {'name': alertmanager_service_name},
        {'enable': False},
      ]
    }
    config['alertmanager_config'] = {
      'file.absent': [
        {'name': alertmanager_config_path },
        {'require': ['alertmanager_service']}
      ]
    }
    if os.path.exists(alertmanager_templates_dir):
      for filename in os.listdir(alertmanager_templates_dir):
        full_path = os.path.join(alertmanager_templates_dir, filename)
        config_section = f"alertmanager_purge_template_{filename}"
        config[config_section] = {
            'file.absent': [
              {'name': full_path },
              {'require': ['alertmanager_service']},
              {'require_in':    ['alertmanager_packages']},
            ]
          }
    config['alertmanager_packages'] = {
      'pkg.purged': [
        {'pkgs': alertmanager_packages},
        {'require': ['alertmanager_config']}
      ]
    }

  return config
