#!/bin/sh

# MacDNA - CrashPlan Backup Percentage Repair Script
# Description: This script attempts to "repair" the related problem
# Written By: Arek Sokol (arek@gene.com)
# Last Modified: 08/25/2011

# Standard Script Common
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/common.sh"

begin

StatusMSG "$Script" "Crashplan Maintenance" uiphase
StatusMSG "$Script" "Determining Backup Percentage" uistatus
# Re-install the latest version of the CrashPlan client
/usr/sbin/installer -package /path/to/crashplan*.mpkg -target /

sleep 5

# Nothing to repair - Sorry... 
die 0