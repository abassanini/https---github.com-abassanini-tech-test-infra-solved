#!/usr/bin/env bash
#
# Shell to stop all docker containers
# Using environment variables
#

source utils/env.sh
source utils/common.sh
test_target $TARGET_IP

echo "Stopping docker"

docker run --rm \
    --name ansible \
    -e APP_USER=${APP_USER} \
    -e TARGET_IP=${TARGET_IP} \
    -v $PWD/ansible:/ansible \
    epicsoft/ansible ansible-playbook \
        -i /ansible/inventory/hosts \
        --vault-password-file /ansible/.vault.pass \
        /ansible/site-shutdown.yml