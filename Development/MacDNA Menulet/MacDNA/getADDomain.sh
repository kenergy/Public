#!/bin/bash
# getADDomain.sh
# GNE Mac Status
#
# Created by Zack Smith on 8/24/11.
# Copyright 2011 318. All rights reserved.


declare -x awk="/usr/bin/awk"
declare -x adinfo="/usr/bin/adinfo"

if [ -x "$adinfo" ] ; then
	declare AD_DOMAIN="$($adinfo |
								$awk '/Joined to domain:/{print $NF}')"
	echo "$AD_DOMAIN"
	exit 0
else
	# Trigger Failure Notification
	exit 1
fi