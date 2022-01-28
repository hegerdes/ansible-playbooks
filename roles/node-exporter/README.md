# Role node-exporter

## Purpose
Installs node-exporter to the host and enables automatic statup via service.  
Allows to scrape host metrics via Prometheus. Make sue port 9100 is open **only** for the subnet 


## Defaults
```yml
# node-exporter options.
node_exporter_listen_interface: '0.0.0.0:9100'
node_exporter_args: '--web.listen-address={{ node_exporter_listen_interface }} --path.rootfs="/"'

```
