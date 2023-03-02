FROM python:3.11-slim-bullseye

WORKDIR /app
COPY requirements.txt /app/requirements.txt

# Install nodejs, ssh, rsync and other needed packages
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl nano gpg ssh-client jq net-tools ca-certificates iputils-ping iproute2 rsync \
    && if [ "$(uname -m)" != "x86_64" ]; then \
        apt-get install -y --no-install-recommends make gcc libc6-dev libffi-dev; \
    fi && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key \
    | gpg --dearmor -o /usr/share/keyrings/nodejs-archive-keyring.gpg \
    && export NODE_ARCH="arch=amd64 signed-by=/usr/share/keyrings/nodejs-archive-keyring.gpg" \
    && echo "deb [$NODE_ARCH] https://deb.nodesource.com/node_16.x bullseye main" \
    > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    nodejs && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir -r requirements.txt \
    && apt-get remove -y cargo rustc make gcc libc6-dev libffi-dev && apt-get autoremove -y

# Data and Labels
COPY . /app/playbooks
ARG COMMIT_HASH="none"
ARG COMMIT_TAG="none"
ENV COMMIT_HASH=$COMMIT_HASH
ENV COMMIT_TAG=$COMMIT_TAG
ENV TZ=Europe/Berlin
LABEL commit-hash=$COMMIT_HASH
LABEL commit-tag=$COMMIT_TAG
ENV ANSIBLE_CONFIG=/app/playbooks/ansible.cfg

ENTRYPOINT [ "/app/playbooks/ansible-entrypoint.sh" ]
