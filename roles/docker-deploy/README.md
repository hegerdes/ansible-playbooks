# Role docker-deploy

## Purpose
To deploy one or multiple docker applications to a server via Docker. Can be done via compose (default) or swarm 


## Defaults
```yml
# Deploy app via Docker

# Use stack deploy mode or compose mode
docker_deploy_use_swarm_mode: no
docker_deploy_src_config_files: srv/
docker_deploy_dst_config_files: /srv/
docker_deploy_app_name: myapp

docker_deploy_services_to_install:
  - docker-compose.yml
```
