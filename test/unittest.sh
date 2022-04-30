#!/bin/bash
# Enable console output
set -x

# Declare a read-only global symbol which each tag starts with
VERSIONSYMBOL="v"
readonly VERSIONSYMBOL

# Declare the read-only sandbox folder name for unt testing
SANDBOXFOLDER="sandbox"
readonly SANDBOXFOLDER

# Declare the read-only sandbox file name for unt testing
SANDBOXFILE="sandbox.txt"
readonly SANDBOXFILE

# Declare the read-only initial version for unt testing
INITIALVERSION="1.0.0"
readonly INITIALVERSION

# Declare a global associated array that contains tag and commit hash pairs
declare -A EXPECTEDRESULTS

InitializeSandbox () {
	mkdir $SANDBOXFOLDER
	cd $SANDBOXFOLDER
	# Initalize the sandbox repo within the current repo
	git init
	# Create the sandbox file
	touch $SANDBOXFILE
	# Stage the sandbox file creation
	git add .
	# Commit the sandbox file creation
	git commit -m "Initial commit"
	cd ..
	# Add the sandbox repo as the current repo sub-module
	git submodule add "./${SANDBOXFOLDER}"
}

AddTag () {
	CURRENTVERSION=$1

	cd $SANDBOXFOLDER
	# (Over)write the current version to the sandbox file as a dummy change
	echo "${CURRENTVERSION}" > $SANDBOXFILE
	# Stage the dummy change
	git add .
	# Commit the dummy change
	git commit -m "Commit version ${CURRENTVERSION}"
	# Create the tag by concatting the version symbol and the version itself
	TAG="${VERSIONSYMBOL}${CURRENTVERSION}"
	# Add the tag
	git tag "${TAG}"
	# Pop back the current directory
	cd ..
}

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
	RESULT="${NEWMAJORVERSION}.${NEWMINORVERSION}.${NEWPATCHVERSION}"

	echo "$RESULT"
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
	RESULT="${NEWMAJORVERSION}.${NEWMINORVERSION}.${NEWPATCHVERSION}"

	echo "$RESULT"
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
	RESULT="${NEWMAJORVERSION}.${NEWMINORVERSION}.${NEWPATCHVERSION}"

	echo "$RESULT"
}

RegisterTagAlias () {
	VERSIONALIAS=$1

	# Join the version symbol and the version alias by a '.' character as the tag alias
	TAGALIAS="${VERSIONSYMBOL}${VERSIONALIAS}"
	# Get the last commit hash
	LASTCOMMIT="$(git rev-parse HEAD)"
	# Add the tag-commit pair to the expected result dictionary
	EXPECTEDRESULTS["${TAGALIAS}"]=$LASTCOMMIT
}

RegisterMajorTagAlias () {
	CURRENTVERSION=$1

	# Split the version by a '.' character
	VERSIONARRAY=(${CURRENTVERSION//./ })

	MAJORVERSION="${VERSIONARRAY[0]}"
	MINORVERSION="${VERSIONARRAY[1]}"
	# Copy the major version as the tag alias
	VERSIONALIAS="${MAJORVERSION}"
	RegisterTagAlias $VERSIONALIAS
}

RegisterMinorTagAlias () {
	CURRENTVERSION=$1

	# Split the version by a '.' character
	VERSIONARRAY=(${CURRENTVERSION//./ })

	MAJORVERSION="${VERSIONARRAY[0]}"
	MINORVERSION="${VERSIONARRAY[1]}"
	# Join the major version and the minor version by a '.' character as the tag alias
	VERSIONALIAS="${MAJORVERSION}.${MINORVERSION}"
	RegisterTagAlias $VERSIONALIAS
}

InitializeSandbox

CURRENTVERSION=$INITIALVERSION
AddTag $CURRENTVERSION

CURRENTVERSION=$(IncrementPatchVersion $CURRENTVERSION)
AddTag $CURRENTVERSION
RegisterMinorTagAlias $CURRENTVERSION

CURRENTVERSION=$(IncrementMinorVersion $CURRENTVERSION)
AddTag $CURRENTVERSION

CURRENTVERSION=$(IncrementPatchVersion $CURRENTVERSION)
AddTag $CURRENTVERSION
RegisterMinorTagAlias $CURRENTVERSION

CURRENTVERSION=$(IncrementMinorVersion $CURRENTVERSION)
AddTag $CURRENTVERSION
RegisterMinorTagAlias $CURRENTVERSION
RegisterMajorTagAlias $CURRENTVERSION

CURRENTVERSION=$(IncrementMajorVersion $CURRENTVERSION)
AddTag $CURRENTVERSION

CURRENTVERSION=$(IncrementPatchVersion $CURRENTVERSION)
AddTag $CURRENTVERSION

CURRENTVERSION=$(IncrementPatchVersion $CURRENTVERSION)
AddTag $CURRENTVERSION
RegisterMinorTagAlias $CURRENTVERSION
RegisterMajorTagAlias $CURRENTVERSION

for key in "${!EXPECTEDRESULTS[@]}"; do
    echo "$key ${EXPECTEDRESULTS[$key]}"
done