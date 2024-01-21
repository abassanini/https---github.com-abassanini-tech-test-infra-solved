#!/usr/bin/env bash
#
# test shell to run ansible with docker
# Using environment variables
#


############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   cat <<eoh
   Runs a clock web application, deploys it using Ansible,
     and run it via Docker.

   Ref: "https://github.com/immfly/tech-test-infra"

   Syntax: ${0} [-t|u|p|w|a|h]
   Options:
   -t     Target IP address.
   -u     User to execute the application.  Default: ${APP_USER}
   -p     Application port.  Default: ${APP_PORT}
   -w     Web port.  Default: ${WEB_PORT}
   -a     Containers action.  Valid values: start|stop.
            If 'start' is provided, just the containers plays will be executed.
            If 'stop' is provided, the containers are going to stop.
            If no action is provided, all the playbooks will run:
              docker-install, app-install, web-configure, etc
         Default: Run all playbooks.
   -h     Print this Help.
eoh
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

source utils/env.sh
source utils/common.sh

# Get the options
while getopts "t:u:p:w:a:h" option; do
   case $option in
      t) # set target IP address
         TARGET_IP="${OPTARG}";;
      u) # set app user
         APP_USER="${OPTARG}";;
      p) # set app port
         APP_PORT="${OPTARG}";;
      w) # set web port
         WEB_PORT="${OPTARG}";;
      a) # container action.  Default run all playbooks
         if [ "${OPTARG}" == "start" ]; then
            TAGS="--tags ${OPTARG}"
         elif [ "${OPTARG}" == "stop" ]; then
            TAGS="--tags never"
         else
            echo "Invalid action.  Use only 'start' or 'stop' as action"
            exit 2
         fi;;
      h) # display Help
         Help
         exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

test_target "${TARGET_IP}"
echo "Running docker"

docker run --rm \
    --name ansible \
    -e APP_USER="${APP_USER}" \
    -e APP_PORT="${APP_PORT}" \
    -e WEB_PORT="${WEB_PORT}" \
    -e TARGET_IP="${TARGET_IP}" \
    -v "${PWD}"/ansible:/ansible \
    -v "${PWD}"/docker:/docker \
    epicsoft/ansible ansible-playbook \
        -i /ansible/inventory/hosts \
        --vault-password-file /ansible/.vault.pass \
        /ansible/main.yml ${TAGS}
