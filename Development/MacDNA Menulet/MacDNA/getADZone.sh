#!/bin/sh

# getADZone.sh
# GNE Mac Status
#
# Created by Zack Smith on 8/24/11.
# Copyright 2011 318. All rights reserved.
declare -x awk="/usr/bin/awk"
declare -x adinfo="/usr/bin/adinfo"

if [ -x "$adinfo" ] ; then
	declare CENT_ZONE="$($adinfo |
								$awk -F'/' '/Zone:/{print $NF}' |
								$awk '{print $NF}')"
	echo "Centrify DC Zone: $CENT_ZONE"
	exit 0
else
	# Trigger Failure Notification
	exit 1
fi
