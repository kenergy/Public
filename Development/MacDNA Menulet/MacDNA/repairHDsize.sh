#!/bin/sh

# MacDNA - HD Size Repair Script
# Description: This script attempts to "repair" the related problem
# Written By: Arek Sokol (arek@gene.com)
# Last Modified: 08/25/2011

# Standard Script Common
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/common.sh"
begin

StatusMSG "$Script" "Hard Drive Check" uiphase
StatusMSG "$Script" "Determining Storage Capacity" uistatus

sleep 5

# Nothing to repair - Sorry... 
die 0