# Hetzner Role

Create or delete Hetzner VM

Defaults:
```yml
hetzner_api_key: '{{ lookup("env","HETZNER_KEY") }}'
hetzner_default_server_size: cx11
hetzner_default_server_location: nbg1
hetzner_default_server_image: debian-11
hetzner_default_vnet_name: my-network

# VM configs
hetzner_vms: []
# Example
# hetzner_vms:
#   - name: waf
#     image: debian-11
#     location: nbg1
#     size: cx11
#     intern_ip: 10.10.0.2
#     state: present
#     ssh_keys:
#       - <Key_name>
```
