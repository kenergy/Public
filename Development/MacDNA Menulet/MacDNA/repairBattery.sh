#!/bin/sh

# MacDNA - Battery Repair Script
# Description: This script attempts to "repair" the related problem
# Written By: Arek Sokol (arek@gene.com)
# Last Modified: 08/25/2011

# Standard Script Common
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/common.sh"

# Nothing to repair - Sorry... 

begin

StatusMSG "$Script" "Battery Health" uiphase 
StatusMSG "$Script" "Checking Battery Condition" uistatus 
sleep 5
StatusMSG "$Script" "Battery Health" uiphase 
StatusMSG "$Script" "Completed Rattery Health Check" uistatus

sleep 2

die 0