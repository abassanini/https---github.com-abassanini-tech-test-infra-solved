#!/usr/bin/env bash
#
# Main shell to run ansible with docker
# Using environment variables
#

source utils/env.sh
source utils/common.sh
test_target $TARGET_IP

echo "Running docker"

docker run --rm \
    --name ansible \
    -e APP_USER=${APP_USER} \
    -e APP_PORT=${APP_PORT} \
    -e WEB_PORT=${WEB_PORT} \
    -e TARGET_IP=${TARGET_IP} \
    -v $PWD/ansible:/ansible \
    -v $PWD/docker:/docker \
    epicsoft/ansible ansible-playbook \
        -i /ansible/inventory/hosts \
        --vault-password-file /ansible/.vault.pass \
        /ansible/site.yml