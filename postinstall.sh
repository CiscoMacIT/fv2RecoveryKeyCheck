#!/usr/bin/env bash

## HEADER
# Script Title: fv2RecoveryKeyCheck postinstall
# Author: Jacob Davidson <jadavids@cisco.com>

if [[ -f /Library/LaunchDaemons/com.cisco.fv2recoverykeycheck.plist ]]
	then
		launchctl unload /Library/LaunchDaemons/com.cisco.fv2recoverykeycheck.plist
fi

sleep 3

launchctl load /Library/LaunchDaemons/com.cisco.fv2recoverykeycheck.plist