# fv2RecoveryKeyCheck
Service to enforce FileVault 2 Recovery Keys as one-time use

If using for your own institution, update paths, labels, service names, etc.

Create pkg installer to deliver fv2RecoveryKeyCheck.sh, com.cisco.fv2recoverykeycheck.plist, and run postinstall.sh. Add to a policy in Jamf to be called by enforce payload.

Code was written in 2015 and as such may require updates for current or future macOS releases.
No warrant or support is intended with the sharing of this code.

--------------------------------------------------------------------------

fv2RecoveryKeyCheckEnforce.sh - Jamf-side script to be run inside a policy

fv2RecoveryKeyCheck.sh - Client-side script called by LaunchDaemon

com.cisco.fv2recoverykeycheck.plist - LaunchDaemon

postinstall.sh - Unloads and loads service as part of installer PKG

-------------------------------------------------------------------------
