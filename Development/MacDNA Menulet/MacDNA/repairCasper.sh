#!/bin/sh

# MacDNA - Casper Repair Script
# Description: This script attempts to "repair" the related problem
# Written By: Arek Sokol (arek@gene.com)
# Last Modified: 08/25/2011

# Standard Script Common
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/common.sh"

begin

StatusMSG "$Script" "Casper Health Check" uiphase
StatusMSG "$Script" "Re-installing the Casper Client" uistatus
StatusMSG "$Script" "Re-installing gInstall" uistatus

# Install the current version of the Casper Client
sudo /usr/sbin/installer -package /path/to/casperclientinstall*.pkg -target /

die 0