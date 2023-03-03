# Role maintenance

## Purpose
This role performs maintenance tasks wich include:
 * update apt-cache:
 * list updates:
 * post updates to gitlab:
 * perform updates:
 * perfom backup tasks:

## How to run:
```bash
ansible-playbook -i <INVENTROY_NAME> playbooks/maintenance.yml [--tags mytags ]
```

## Defaults
```yml

maintenance_run_upgrades: no
maintenance_run_backup: yes
maintenance_post_to_git: yes
maintenance_git_token: '{{ lookup("env", "GITLAB_API_TOKEN") | default("none", true) }}'
maintenance_git_host: https://gitlab.com
maintenance_git_repo: '{{ lookup("env", "CI_LOG_PROJECT_ID") | default("165", true) }}'
maintenance_git_name: Gitlab CI
maintenance_git_mail: git-ci@example.com
maintenance_git_assignee_id: '{{ lookup("env", "GITLAB_USER_ID") | default("13", true) }}' # Henrik Gerdes

```
