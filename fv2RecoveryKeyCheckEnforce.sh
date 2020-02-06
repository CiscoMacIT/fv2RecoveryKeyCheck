#!/bin/bash

## HEADER
# Script Title: FV2 Recovery Key Used Check Enforce
# Author: Jacob Davidson <jadavids@cisco.com>

## DEFINITIONS
scriptFile="/Library/CiscoIT/Scripts/FV2RecoveryCheck/fv2RecoveryKeyCheck.sh"
statusFile="/Library/CiscoIT/Scripts/FV2RecoveryCheck/recovered"

if [[ -f "/usr/local/jamf/bin/jamf" ]]
	then
		jamfBinary="/usr/local/jamf/bin/jamf"
	else
		if [[ -f "/usr/sbin/jamf" ]]
			then
				jamfBinary="/usr/sbin/jamf"
		fi
fi

#This variable will remain 0 if no issues are found below
runPolicy=0

fv2RecoveryCheckInstalled=0

#Declare a simple array to hold all files related to the daemon
fv2CheckFiles=(
    '/Library/LaunchDaemons/com.cisco.fv2recoverykeycheck.plist'
    '/Library/CiscoIT/Scripts/FV2RecoveryCheck/fv2RecoveryKeyCheck.sh'
    )

#Function will loop through files that make up the daemon
chkFV2Files()
{
for EachFile in "${fv2CheckFiles[@]}"; do
    [[ -e "$EachFile" ]] && fv2RecoveryCheckInstalled=$(expr $fv2RecoveryCheckInstalled + 1)
done

if [[ $fv2RecoveryCheckInstalled -lt 2 ]]; then
    (( runPolicy++ ))
fi
}

#Evaluates if Daemon is loaded and then running properly
isfv2RecoveryCheckRunning(){

    if [[ $(launchctl list | grep -c com.cisco.fv2recoverykeycheck) -ne 0 ]];then

        echo "fv2recoverykeycheck is running"

        if [[ "$(launchctl list | grep -w com.cisco.fv2recoverykeycheck | awk '{ print $2 }')" != "0" ]];then

            (( runPolicy++ ))

            echo "fv2recoverykeycheck had exit code greater than 0"

        else

            echo "fv2recoverykeycheck had an exit code of 0"

        fi

    else

        echo "fv2recoverykeycheck is not running"

        (( runPolicy++ ))

    fi

}

#begin main

#Check for missing files
chkFV2Files

#Make sure it's loaded and running without error
isfv2RecoveryCheckRunning

#Greater than 0 if any check found a problem
if [[ $runPolicy -gt 0 ]]; then

    #If only 1 change the output message to be proper
    if [[ $runPolicy -gt 0 ]] && [[ $runPolicy -lt 2 ]];then

        echo "Found: $runPolicy reason to reinstall fv2recoverykeycheck"

    else  #If greater than 1 change the output message to be proper

        echo "Found: $runPolicy reasons to reinstall fv2recoverykeycheck"

        launchctl unload -F /Library/LaunchDaemons/com.cisco.fv2recoverykeycheck.plist

    fi

    #Remove all files that make up the old or busted daemon
    rm "${fv2CheckFiles[@]}"

    #Run policy event to install current daemon package
    $jamfBinary policy -event fv2RecoveryCheckPayload

fi

if [[ -f $statusFile ]]
	then
		echo "Status file found. Recovery key has been used. Reissuing..."
		# Call JSS policy to issue new recovery key
		$jamfBinary policy -event fvIssueNewKey
		recoveryKeyUsed=$(fdesetup usingrecoverykey)
		if [ "$recoveryKeyUsed" == "false" ]
			then
				echo "Recovery successfully replaced. Exiting..."
				rm $statusFile
			else
				echo "Recovery was NOT issued. Leaving status file. Exiting.."
		fi		
	else
		echo "Recovery key has NOT been used. Exiting..."
fi