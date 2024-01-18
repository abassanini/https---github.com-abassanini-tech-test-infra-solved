#!/usr/bin/env bash
#
# Script to obtain IP from virsh
#

virsh domifaddr immfly-debian10 | grep "52:54:00:c0:e9:b1" | awk '{print $4}' | sed 's/\/[0-9]*$//'
