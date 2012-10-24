#!/bin/bash
echo "Checking Software Updates"
# Commands used by this script
declare -x softwareupdate="/usr/sbin/softwareupdate"
declare -x grep="/usr/bin/grep"




declare -xi NUMBER_OF_UPDATES="$($softwareupdate -l 2>&1 | $grep -c '*')"
declare -xi NO_UPDATES_AVAILABLE="$($softwareupdare -l 2>&1 | $grep -c 'No new software available')"

if [[ NO_UPDATES_AVAILABLE -gt 0 ]]; then
    NUMBER_OF_UPDATES = 0
fi

exit $NUMBER_OF_UPDATES
