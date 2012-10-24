#!/bin/sh

# MacDNA - DiskUsage Repair Script
# Description: This script attempts to "repair" the related problem
# Written By: Arek Sokol (arek@gene.com)
# Last Modified: 08/25/2011

# Standard Script Common
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/common.sh"

begin

StatusMSG "$Script" "Hard Drive Check" uiphase
StatusMSG "$Script" "Verifying Disk Space Availability" uistatus

sleep 5

StatusMSG "$Script" "Hard Drive Check" uiphase
StatusMSG "$Script" "Completed Disk Space Availability Check" uistatus

sleep 2

# Nothing to repair - Sorry... unless we delete most of the users files - which we will NOT.
die 0
