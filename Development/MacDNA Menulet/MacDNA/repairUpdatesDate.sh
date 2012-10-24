#!/bin/sh

# MacDNA - Apple Software Update Date Run Repair Script
# Description: This script attempts to "repair" the related problem
# Written By: Arek Sokol (arek@gene.com)
# Last Modified: 08/25/2011


declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/common.sh"

begin

StatusMSG "$Script" "Apple Software Updates" uiphase
StatusMSG "$Script" "Determining Last Update Date" uistatus

sleep 5

die 0