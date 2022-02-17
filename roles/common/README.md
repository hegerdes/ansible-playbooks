# Role common

## Purpose
This role performs basic operation that should be done on every managed host. Including
 * Installing:
    * software-properties-common
    * apt-transport-https
    * ca-certificates
    * wget
    * curl
    * pass
    * gnupg
    * gnupg2
    * openssl
    * lsb-release
    * python3-pip
    * python3-requests
    * python3-jsondiff
    * python3-yaml
    * unzip
    * git
  * Setting hostnames of all hosts in the play to the IP in /etc/hosts
  * Installing additional SSH-Keys
  * Installs cron
  * Installs cronjobs if any specified


## Defaults
```yml
# Install extra packages
extra_packages: []

# List of key_paths
common_ssh_keys: []
# Example
# common_ssh_keys:
#   - filename: '{{ inventory_dir }}/key.pub'
#     state: present                # optional
#     user: root                    # optional
#     key_options: ''               # optional

# Key value pairs of hostname: ip
# Default is ansibe_host: ansible_ip
internal_hostnames: []

# List of cron jobs
common_cron_jobs: []
# Example structure
# cron_jobs:
#   - name: Ping Google
#     job: ping google.de
#     weekday: '*'
#     month: '*'
#     minute: '*'
#     hour: '*'
#     day: '24'
#     state: present
#     user: null
```