# Role docker

## Purpose
This role installs the latest Docker ce|ee - version. Can configure the daemon, setup swarm mode and install portainer. 


## Defaults
```yml
---
# Docker edition
# Choice: ce|ee
docker_edition: 'ce'

# Docker Compose options.
docker_install_compose: true
docker_compose_version: latest

# A list of users who will be added to the docker group.
docker_users: []

# Docker daemon options as a dict
docker_daemon_options: {}

# Docker regesties
docker_regesties: []
# Example
# docker_regesties:
#   - regestry: https://index.docker.io/v1/
#     username: MyUser
#     password: MySuperSecurPW

# Plugins
docker_install_loki_log_plugin: true

# SWARM
docker_init_swarm: true

# Specify swarm managers and their listen ip
docker_swarm_manager_and_advertise_addr: {}
# Example
# docker_swarm_manager_and_advertise_addr:
#   hostname: ip:port
#   hostname: interface:port

# Specify mapping of swarm nodes
docker_swarm_worker_mapping: {}
# Key is the hostname of the node that should join the
# node specified as the value of the leader key
# the role is for the type of join. Default is worker
# Example:
# docker_swarm_worker_mapping:
#   raspberrypi:
#     leader: raspberrypi:2377
#     role: Worker

# Portainer
docker_install_portainer: true

docker_portainer_src: "{{'portainer-agent-stack.yml' if (docker_init_swarm) else 'portainer-agent.yml'}}"
docker_portainer_dst_stack: /srv/portainer/portainer-agent-stack.yml

# Clean docker host every 03:30 on Saturday
docker_cron_jobs:
  - name: Remove stoped containers
    job: echo "Running docker container prune -f" >> /var/log/cron.log && docker container prune -f >> /var/log/cron.log
    weekday: '6'
    month: '*'
    minute: '30'
    hour: '03'
    day: '*'
    state: present
    user: root
  - name: Remove dangling images
    job: echo "Running docker image prune -f" >> /var/log/cron.log && docker image prune -f >> /var/log/cron.log
    weekday: '6'
    month: '*'
    minute: '45'
    hour: '03'
    day: '*'
    state: present
    user: root

```