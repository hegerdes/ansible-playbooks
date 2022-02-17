# Role firewalld

## Purpose
Install and configure firewalld


## Defaults
```yml
firwalld_rules:
  - name: Setup public net
    zone: public
    interface: eth0
# Example
  # - name: http
  #   service: http
  #   zone: public
  #   interface: eth0
  # - name: http
  #   service: http
  #   zone: public
  #   interface: eth0
  # - name: http-internal
  #   zone: internal
  #   port: 80/tcp

```