#!/usr/bin/env bash
#
# Commun functions
#

function validate_ssh_access {
    echo "Testing SSH access..."
    if $(timeout 30 bash -c "cat < /dev/null > /dev/tcp/${1}/22"); then
        echo "SSH access OK"
    else
        echo "SSH access NOT OK.  Please check network access"
        exit 2
    fi
}

function test_target {
    if [ -z "$1" ]; then
        echo "Env variable TARGET_IP not provided"
        echo "Trying to obtain TARGET_IP address..."
        TARGET_IP=$(sh utils/virsh-ip.sh)

        if [ -z "$TARGET_IP" ]; then
            cat << EOF
            No IP found.  
            
            Please check the following:
                - Command "virsh" is installed
                - VM "immfly-debian10" is up and running locally
                - There is access to the VM
                - Try this command from your shell session:
                    virsh domifaddr immfly-debian10 | grep "52:54:00:c0:e9:b1" | awk '{print $4}' | sed 's/\/[0-9]*$//'

            If VM "immfly-debian10" is running remotely or if it's not possible to run the local commands
            please set shell variable TARGET_IP with the target VM IP address and run this script again.
            Ex:

                export TARGET_IP=<a.valid.ip.address>
                export TARGET_IP=192.168.122.190
EOF
            exit 2
        fi
    fi
    export TARGET_IP
    echo "TARGET_IP configured: ${TARGET_IP}"

    validate_ssh_access ${TARGET_IP}

}
