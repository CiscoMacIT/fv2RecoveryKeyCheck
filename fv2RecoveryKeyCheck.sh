#!/bin/bash

## HEADER
# Script Title: FV2 Recovery Key Used Check
# Author: Jacob Davidson <jadavids@cisco.com>

## DEFINITIONS
SoftwareTitle=fv2RecoveryKeyUsedCheck
LogFile="/Library/Logs/CiscoIT/$SoftwareTitle.log"
TimeStamp="$(date "+%Y-%m-%d %H:%M:%S")"
consoleUser=$(stat -f %Su '/dev/console')
statusFile="/Library/CiscoIT/Scripts/FV2RecoveryCheck/recovered"
counter=1

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$consoleUser] [$SoftwareTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

if [[ -f "/usr/local/jamf/bin/jamf" ]]
	then
		jamfBinary="/usr/local/jamf/bin/jamf"
	else
		if [[ -f "/usr/sbin/jamf" ]]
			then
				jamfBinary="/usr/sbin/jamf"
		fi
fi

jssConnectCheck=$($jamfBinary checkJSSConnection -retry 0 | grep -c "The JSS is available")

## FUNCTIONS
jssCheck()
{
writeLog "Checking connection to JSS"
while [ $jssConnectCheck != 1 ]
	do
		if [ $counter -gt 9 ]
			then
				if [ $jssConnectCheck != 1 ]
					then
						writeLog "Unable to connect to JSS."
						exit 1
					else
						writeLog "JSS contacted on attempt $counter"
						break
				fi
			else
				if [ $jssConnectCheck != 1 ]
					then
						writeLog "JSS unreachable. Waiting..."
					else
						writeLog "JSS contacted on attempt $counter"
						break
				fi
		fi
		counter=$(expr $counter + 1)
		sleep 10
		jssConnectCheck=$($jamfBinary checkJSSConnection -retry 0 | grep -c "The JSS is available")
	done
}

## BODY

# Check to see if recovery key was used to log in
recoveryKeyUsed=$(fdesetup usingrecoverykey)

if [ "$recoveryKeyUsed" == "true" ]
	then
		writeLog "Recovery key has been used. Reissuing..."
		# Write offline file
		touch $statusFile
		# Verify can reach JSS
		jssCheck
		# Call JSS policy to issue new recovery key
		$jamfBinary policy -event fvIssueNewKey
		recoveryKeyUsed=$(fdesetup usingrecoverykey)
		if [ "$recoveryKeyUsed" == "false" ]
			then
				writeLog "Recovery key successfully replaced. Exiting..."
				rm $statusFile
			else
				writeLog "Recovery key was NOT issued. Leaving status file. Exiting.."
		fi
	elif [[ -f $statusFile ]]
		then
		writeLog "Status file found. Recovery key has been used. Reissuing..."
		# Verify can reach JSS
		jssCheck
		# Call JSS policy to issue new recovery key
		$jamfBinary policy -event fvIssueNewKey
		recoveryKeyUsed=$(fdesetup usingrecoverykey)
		if [ "$recoveryKeyUsed" == "false" ]
			then
				writeLog "Recovery successfully replaced. Exiting..."
				rm $statusFile
			else
				writeLog "Recovery was NOT issued. Leaving status file. Exiting.."
		fi		
	else
		writeLog "Recovery key has NOT been used. Exiting..."
fi

exit 0