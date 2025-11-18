# Help us make nice squiggly bars and lines

follow pillar.example

## Required salt master config:

```
file_roots:
  base:
    - {{ salt_base_dir }}/salt
    - {{ formulas_base_dir }}/barsandsquiggles/salt
pillar_roots:
  base:
    - {{ formulas_base_dir }}/barsandsquiggles/pillar/
```

## cfgmgmt-template integration

if you are using our [cfgmgmt-template](https://github.com/darix/cfgmgmt-template) as a starting point the saltmaster you can simplify the setup with:

```
git submodule add https://github.com/darix/barsandsquiggles formulas/barsandsquiggles
ln -s /srv/cfgmgmt/formulas/barsandsquiggles/config/enable_barsandsquiggles.conf /etc/salt/master.d/
systemctl restart saltmaster
```

## License

[AGPL-3.0-only](https://spdx.org/licenses/AGPL-3.0-only.html)

