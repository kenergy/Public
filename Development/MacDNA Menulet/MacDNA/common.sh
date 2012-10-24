#!/bin/sh

# common.sh
# GNE Mac Status
#
# Created by Zack Smith and Arek Sokol 8/26/11.
# Copyright 2011 Genentech. All rights reserved.


# The tmp file we save our numeric install percentage to
export InstallProgressFile="/private/tmp/com.gene.pleasewait.installprogress"

# This is the tmp file that we save our progress information to.
export InstallProgressTxt="/private/tmp/com.gene.pleasewait.progress"
# This is the tmp file that we save our phase to ( bold text )
export InstallPhaseTxt="/private/tmp/com.gene.pleasewait.phase"

export Script="${0##*/}" 
export ScriptName="${Script%%\.*}"
export ProjectName="MacDNA"

export LogFile="/Library/Logs/Genentech/$ProjectName.log"

# Commands Required by these functions
export awk="/usr/bin/awk"
export date="/bin/date"
export dscl="/usr/bin/dscl"
export chflags="/usr/bin/chflags"
export rm="/bin/rm"
export tee="/usr/bin/tee"
export find="/usr/bin/find"
export ifconfig="/sbin/ifconfig"
export ioreg="/usr/sbin/ioreg"
export sw_vers="/usr/bin/sw_vers"
export dsmemberutil="/usr/bin/dsmemberutil"
export dscacheutil="/usr/bin/dscacheutil"
export dscl="/usr/bin/dscl"
export rm="/bin/rm"
export mv="/bin/mv"
export ln="/bin/ln"
export touch="/usr/bin/touch"

setInstallPercentage(){
	declare InstallPercentage="$1"
	echo "$InstallPercentage" >> "$InstallProgressFile"
	export CurrentPercentage="$InstallPercentage"
}

# Generates log status message
StatusMSG(){ # Status message function with type and now color!
	declare FunctionName="$1" StatusMessage="$2" MessageType="$3" CustomDelay="$4"
	# Set the Date Per Function Call
	declare DATE="$($date)"
	if [ "$EnableColor" = "YES"  ] ; then
		# Background Color
		declare REDBG="41"		WHITEBG="47"	BLACKBG="40"
		declare YELLOWBG="43"	BLUEBG="44"		GREENBG="42"
		# Foreground Color
		declare BLACKFG="30"	WHITEFG="37" YELLOWFG="33"
		declare BLUEFG="36"		REDFG="31"
		declare BOLD="1"		NOTBOLD="0"
		declare format='\033[%s;%s;%sm%s\033[0m\n'
		# "Bold" "Background" "Forground" "Status message"
		printf '\033[0m' # Clean up any previous color in the prompt
	else
		declare format='%s\n'
	fi
	case "${MessageType:-"progress"}" in
		uiphase ) \
			printf $format $NOTBOLD $WHITEBG $BLACKFG "---> $ScriptName:($FunctionName) Displaying UI Message - $StatusMessage"  | $tee -a "${LogFile%%.log}.color.log" ;		
			printf "%s\n" "$StatusMessage" > "$InstallPhaseTxt" ;
			sleep ${CustomDelay:=1} ;;
		uistatus ) \
			printf $format $NOTBOLD $WHITEBG $BLACKFG "---> $ScriptName:($FunctionName) Displaying UI Message - $StatusMessage"  | $tee -a "${LogFile%%.log}.color.log" ;		
			printf "%s\n" "$StatusMessage" > "$InstallProgressTxt" ;
			sleep ${CustomDelay:=1} ;;
		progress) \
			printf $format $NOTBOLD $WHITEBG $BLACKFG "---> $ScriptName:($FunctionName) - $StatusMessage"  | $tee -a "${LogFile%%.log}.color.log" ;		
			printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
			# Used for general progress messages, always viewable

		notice) \
			printf $format $NOTBOLD $YELLOWBG $BLACKFG "---> $ScriptName:($FunctionName) - $StatusMessage" | $tee -a "${LogFile%%.log}.color.log" ;
			printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
			# Notifications of non-fatal errors , always viewable

		error) \
			printf "%s\n\a" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" | $tee -a "${LogFile%%.log}.color.log";
			printf "%s\n\a" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile%%.log}.error.log" ;
			printf $format $NOTBOLD $REDBG $YELLOWFG "---> $ScriptName:($FunctionName) - $StatusMessage"  ;;
			# Errors , always viewable

		verbose) \
			printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;
			printf $format $NOTBOLD $WHITEBG $BLACKFG "---> $ScriptName:($FunctionName) - $StatusMessage"  | $tee -a "${LogFile%%.log}.color.log" ;;
			# All verbose output

		header) \
			printf $format $NOTBOLD $BLUEBG $BLUEFG "---> $ScriptName:($FunctionName) - $StatusMessage"  | $tee -a "${LogFile%%.log}.color.log" ;
			printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
			# Function and section headers for the script

		passed) \
			printf $format $NOTBOLD $GREENBG $BLACKFG "---> $ScriptName:($FunctionName) - $StatusMessage" | $tee -a "${LogFile%%.log}.color.log";
			printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
			# Sanity checks and "good" information
		*) \
			printf $format $NOTBOLD $WHITEBG $BLACKFG "---> $ScriptName:($FunctionName) - $StatusMessage" | $tee -a "${LogFile%%.log}.color.log";
			printf "%s\n" "$DATE ---> $ScriptName:($FunctionName) - $StatusMessage" >> "${LogFile:?}" ;;
			# Used for general progress messages, always viewable
	esac
	return 0
} # END StatusMSG()

deleteBridgeFiles(){
	$rm "$InstallProgressTxt" &>/dev/null
	$rm "$InstallPhaseTxt" &>/dev/null
	$rm "$InstallProgressFile" &>/dev/null
}


begin(){
	StatusMSG $FUNCNAME "BEGINNING: $ScriptName - $ProjectName" header
	deleteBridgeFiles
}

die(){
	StatusMSG $FUNCNAME "END: $ScriptName - $ProjectName" header
	setInstallPercentage 99.00
	StatusMSG $FUNCNAME "Step Complete" uistatus 0.5
	deleteBridgeFiles
	unset CurrentPercentage
	exec 2>&- # Reset the error redirects
	exit $1
}