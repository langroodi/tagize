#!/bin/bash
# Enable console output
set -x

# Declare a read-only global symbol which each tag starts with
VERSIONSYMBOL="v"
readonly VERSIONSYMBOL

IncrementMajorVersion () {
	CURRENTVERSION=$1

	# Split the version by '.' character
	VERSIONARRAY=(${CURRENTVERSION//./ })

	# Increment the current major version by one as the new major version
	NEWMAJORVERSION=$((${VERSIONARRAY[0]} + 1))
	# Reset the current minor version to zero as the new minor version
	NEWMINORVERSION="0"
	# Reset the current patch version to zero as the new patch version
	NEWPATCHVERSION="0"
	# Join the new major, minor, and patch versions by a '.' character as the new version
	NEWVERSION="${NEWMAJORVERSION}.${NEWMINORVERSION}.${NEWPATCHVERSION}"

	echo "$NEWVERSION"
}

IncrementMinorVersion () {
	CURRENTVERSION=$1

	# Split the version by '.' character
	VERSIONARRAY=(${CURRENTVERSION//./ })

	# Copy the current major version as the new major version
	NEWMAJORVERSION="${VERSIONARRAY[0]}"
	# Increment the current minor version by one as the new minor version
	NEWMINORVERSION=$((${VERSIONARRAY[1]} + 1))
	# Reset the current patch version to zero as the new patch version
	NEWPATCHVERSION="0"
	# Join the new major, minor, and patch versions by a '.' character as the new version
	NEWVERSION="${NEWMAJORVERSION}.${NEWMINORVERSION}.${NEWPATCHVERSION}"

	echo "$NEWVERSION"
}

IncrementPatchVersion () {
	CURRENTVERSION=$1

	# Split the version by a '.' character
	VERSIONARRAY=(${CURRENTVERSION//./ })

	# Copy the current major version as the new major version
	NEWMAJORVERSION="${VERSIONARRAY[0]}"
	# Copy the current minor version as the new minor version
	NEWMINORVERSION="${VERSIONARRAY[1]}"
	# Increment the current patch version by one as the new patch version
	NEWPATCHVERSION=$((${VERSIONARRAY[2]} + 1))
	# Join the new major, minor, and patch versions by a '.' character as the new version
	NEWVERSION="${NEWMAJORVERSION}.${NEWMINORVERSION}.${NEWPATCHVERSION}"

	echo "$NEWVERSION"
}

MYVERSION="1.0.0"

MYNEWVERSION=$(IncrementPatchVersion $MYVERSION)

MYNEWVERSION=$(IncrementMinorVersion $MYNEWVERSION)

MYNEWVERSION=$(IncrementMajorVersion $MYNEWVERSION)