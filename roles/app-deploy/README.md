# Role app-deploy

## Purpose
To deploy one or multiple applications to a server.


## Defaults
```yml
---
# Deploy app

app_deploy_base_dir: '{{ inventory_dir }}/{{ inventory_hostname }}'
src_config_files: '{{ app_deploy_base_dir }}/srv/'
dst_config_files: /srv/
app_deploy_wait_timeout: '{{ lookup("env","DEPLOY_WAIT_TIMEOUT") | default(30, true) | int }}'
app_deploy_shutdown_command: none
app_deploy_test_command: none
app_deploy_start_command: none

rsync_args: []
# Example
# rsync_args:
#   - "--exclude=.git"

app_deploy_file_permissions: []
# Example
# app_deploy_file_permissions:
#   - name: application.json
#     mode: 0666

```
