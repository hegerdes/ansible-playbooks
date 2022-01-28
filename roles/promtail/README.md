# Role promtail

## Purpose
Installs promtail for log-shipping to the host and enables automatic statup via service.  
By default ships:
 * authlog
 * syslog
 * daemonlog
 * dpkglog


## Defaults
```yml
# promtail options
promtail_config_client_target: 'mgmt'
promtail_config_src_path: promtail-config.yml
promtail_config_dst_path: /srv/promtail/promtail-config.yml

promtail_args: '--client.external-labels=hostname={{ ansible_facts.hostname }} -config.file {{ promtail_config_dst_path }}'

```
