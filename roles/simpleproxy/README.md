# Role simpleproxy

## Purpose
Installs simpleproxy to the host and enables automatic statup via service.  
Allows to forward udp/tcp sockets 


## Defaults
```yml
# simpleproxy options.
simpleproxy_confs:
  - name: example 6500 to 6501
    parameters: -L 127.0.0.1:6500 -R 127.0.0.1:6501 -v
```
