FROM debian:trixie-slim

WORKDIR /app
COPY requirements.txt /app/requirements.txt

# Install nodejs, ssh, rsync and other needed packages
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install --yes --no-install-recommends \
    curl nano gpg ssh-client jq net-tools ca-certificates iputils-ping \
    iproute2 rsync apt-transport-https lsb-release gnupg python3 python3-pip \
    && mkdir -p /etc/apt/keyrings \
    && if [ "$(uname -m)" != "x86_64" ]; then \
    apt-get install --yes --no-install-recommends make gcc python3-dev libc6-dev libffi-dev; \
    fi && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o \
    /usr/share/keyrings/nodejs-archive-keyring.gpg \
    && export NODE_ARCH="arch=`dpkg --print-architecture` signed-by=/usr/share/keyrings/nodejs-archive-keyring.gpg" \
    # && export OS_CODENAME=$(lsb_release -cs) \ # microsoft does not offer packages for trixie yet
    && export OS_CODENAME=bookworm \
    && echo "deb [$NODE_ARCH] https://deb.nodesource.com/node_24.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
    && curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee \
    /etc/apt/keyrings/microsoft.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/microsoft.gpg \
    && echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $OS_CODENAME main" \
    | tee /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs azure-cli \
    && pip3 install --break-system-packages --no-cache-dir -r requirements.txt \
    && apt-get install yq --yes --no-install-recommends \
    && apt-get remove -y make gcc python3-dev libc6-dev libffi-dev && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

# Data and Labels
COPY . /app/playbooks
ARG COMMIT_HASH="none"
ARG COMMIT_TAG="none"
ENV COMMIT_HASH=$COMMIT_HASH
ENV COMMIT_TAG=$COMMIT_TAG
ENV ANSIBLE_CONFIG=/app/playbooks/ansible.cfg
LABEL commit-hash=$COMMIT_HASH
LABEL commit-tag=$COMMIT_TAG
LABEL org.opencontainers.image.description="Ansible Playbook image containing all deps needed to run and bootstrap machines"

ENTRYPOINT [ "/app/playbooks/shared/ansible-entrypoint.sh" ]
