#!/bin/bash

# Make it prittttyyyy
RED='\033[0;31m'
NC='\033[0m'


INVENTORY_DIR=/inventory
PVT_KEY=$INVENTORY_DIR/secrets/maintenance.key


echo "Running Ansible-Playbook image at commit=${COMMIT_HASH}; tag=${COMMIT_TAG}"
if [ ! -f "$PVT_KEY" ]; then
    echo -e "${RED}Private-key file does not exist!${NC}\nMount via Docker with '-v /my/pvt/key:${PVT_KEY}'"
    exit 1
fi

if [ ! -d "$INVENTORY_DIR" ]; then
    echo -e "${RED}Inventory does not exist!${NC}\nMount via Docker with '-v /my/inventory:${INVENTORY_DIR}'"
    exit 1
fi

checkExitCode() {
    if [ $1 -ne 0 ]; then
        echo -e "${RED}Last command returned none zero exit code. Please check${NC}"
        exit 1
    fi
}

echo "Setting up SSH..."
eval $(ssh-agent -s) > /dev/null
cat $PVT_KEY | ssh-add -
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$SSH_HOST_KEY" >> ~/.ssh/known_hosts

echo "Running: ansible-playbook -i /inventory/ansible-inventory.txt $@"
exec ansible-playbook -i /inventory/ansible-inventory.txt $@
