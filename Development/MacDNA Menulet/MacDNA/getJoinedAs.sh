#!/bin/bash

# getJoinedAs.sh
# Mac DNA
#
# Created by Zack Smith on 8/24/11.
# Copyright 2011 Genentech. All rights reserved.
declare -x awk="/usr/bin/awk"
declare -x adinfo="/usr/bin/adinfo"

if [ -x "$adinfo" ] ; then
	declare COMPUTER_ACCOUNT="$($adinfo |
								$awk -F'.' '/Joined as:/{print $1}' |
								$awk '{print $NF}')"
	echo "Joined As: $COMPUTER_ACCOUNT"
	exit 0
else
	# Trigger Failure Notification
	exit 1
fi
