#!/bin/sh

# MacDNA - Apple Software Updates Repair Script
# Description: This script attempts to "repair" the related problem
# Written By: Arek Sokol (arek@gene.com)
# Last Modified: 08/25/2011

# Download and install ALL available Apple Software Updates

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/common.sh"

begin

StatusMSG "$Script" "Apple Software Updates" uiphase
StatusMSG "$Script" "Installing all available updates..." uistatus

rm -R /Library/Receipts/*.pkg
/usr/sbin/softwareupdate -i -a

StatusMSG "$Script" "Apple Software Updates" uiphase
StatusMSG "$Script" "Completed installing all available updates" uistatus

sleep 2

die 0