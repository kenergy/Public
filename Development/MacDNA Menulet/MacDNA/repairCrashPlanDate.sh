#!/bin/sh

# MacDNA - Crashplan Last Backup Date Repair Script
# Description: This script attempts to "repair" the related problem
# Written By: Arek Sokol (arek@gene.com)
# Last Modified: 08/25/2011

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/common.sh"

begin

StatusMSG "$Script" "Crashplan Maintenance" uiphase
StatusMSG "$Script" "Reinstalling the Crashplan Backup Client..." uistatus

# Re-install the latest version of the CrashPlan client
sudo /usr/sbin/installer -package /path/to/crashplan*.mpkg -target /

sleep 10    

die 0