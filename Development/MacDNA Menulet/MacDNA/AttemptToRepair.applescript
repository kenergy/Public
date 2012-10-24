-- AttemptToRepair.applescript
-- GNE Mac Status

-- Created by Zack Smith and Arek Sokol 7/21/11.
-- Copyright 2011 Genentech. All rights reserved.

(* We expect the script to be called*)
-- repair<TestName>.sh
property repairScript : ""
property scriptDirectory : ""
property returnValue : "No repairs are necessary at this time"
-- All Repairs completed successfully

script AttemptToRepair
	tell application "Finder"
		set scriptDirectory to container of (path to me) as text
	end tell
	set thePListPath to POSIX path of "/tmp/gsa.plist"
	tell application "System Events"
		
		set the plist_path to "/tmp/gsa.plist"
		set the plist_file to property list file plist_path
		
		set itemNodes to property list items of property list item "globalStatusArray" of plist_file
		if number of items in itemNodes is equal to 0 then
			set returnValue to "No repairs are necessary at this time"
			return
		end if
		repeat with i from 1 to number of items in itemNodes
			
			set itemNode to item i of itemNodes
			
			set discription to value of property list item "discription" of itemNode as text
			set metric to value of property list item "metric" of itemNode as text
			set reason to value of property list item "reason" of itemNode as text
			set status to value of property list item "status" of itemNode as text
			-- DEBUG: Show Items
			-- display dialog ¬
			-- 	"discription:" & discription & return & ¬
			--	"metric:" & metric & return & ¬
			--	"reason:" & reason & return & ¬
			--	"status:" & status
			if status is not equal to "Passed" then
				set repairScriptName to "repair" & discription & ".sh"
				set repairScriptPath to POSIX path of ((scriptDirectory & repairScriptName) as alias)
				set repairScript to quoted form of repairScriptPath
				-- DEBUG: Show path to script
				-- display dialog repairScript
				-- Prompt for authentication
				do shell script ":" with administrator privileges
				-- Activate the Please Wait window
				open location "macdna://?activate"
				try
					do shell script repairScript with administrator privileges
					set returnValue to "All repairs completed successfully"
				on error
					set returnValue to "Unabled to repair:" & space & discription & space & return & "Repair script failed."
					return
				end try
			end if
		end repeat
		
	end tell
end script
run AttemptToRepair
return returnValue