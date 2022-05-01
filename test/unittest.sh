#!/bin/bash
# Enable console output
set -x

# Declare a read-only global symbol which each tag starts with
VERSIONSYMBOL="v"
readonly VERSIONSYMBOL

# Declare the read-only sandbox folder name for unt testing
SANDBOXFOLDER="sandbox"
readonly SANDBOXFOLDER

# Declare the read-only bash script to be tested during the unt test
BASHSCRIPT="entrypoint.sh"
readonly BASHSCRIPT

# Declare the read-only sandbox file name for unt testing
SANDBOXFILE="sandbox.txt"
readonly SANDBOXFILE

ConfigureGitUser () {
    # Set Git user configuration
    git config --global user.name github-actions[bot]
    git config --global user.email github-actions[bot]@users.noreply.github.com
    
    # Add shared GitHub Workspace as exception due to CVE-2022-24765
    git config --global --add safe.directory /github/workspace
}

InitializeSandbox () {
	mkdir $SANDBOXFOLDER
	cd $SANDBOXFOLDER
	# Initalize the sandbox repo within the current repo
	git init
	# Create the sandbox file
	cp "../../${BASHSCRIPT}" "./${BASHSCRIPT}"
	# Stage the sandbox file creation
	git add .
	# Commit the sandbox file creation
	git commit -m "Initial commit"
	# Pop back the current directory
	cd ..
}

AddSandboxTag () {
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

GetSandboxLastCommit () {
	cd $SANDBOXFOLDER
	# Get the last commit hash
	RESULT="$(git rev-parse HEAD)"
	# Pop back the current directory
	cd ..

	echo "$RESULT"
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

RegisterMajorTagAlias () {
	CURRENTVERSION=$1
	TAGCOMMIT=$2

	# Split the version by a '.' character
	VERSIONARRAY=(${CURRENTVERSION//./ })

	MAJORVERSION="${VERSIONARRAY[0]}"
	# Copy the major version as the tag alias version
	TAGALIASVERSION="${MAJORVERSION}"
	# Add the tag-commit pair to the expected result dictionary
	EXPECTEDRESULTS["${TAGALIASVERSION}"]=$TAGCOMMIT
}

RegisterMinorTagAlias () {
	CURRENTVERSION=$1
	TAGCOMMIT=$2

	# Split the version by a '.' character
	VERSIONARRAY=(${CURRENTVERSION//./ })

	MAJORVERSION="${VERSIONARRAY[0]}"
	MINORVERSION="${VERSIONARRAY[1]}"
	# Join the major version and the minor version by a '.' character as the tag alias version
	TAGALIASVERSION="${MAJORVERSION}.${MINORVERSION}"
	# Add the tag-commit pair to the expected result dictionary
	EXPECTEDRESULTS["${TAGALIASVERSION}"]=$TAGCOMMIT
}

InitializeExpectedResults () {
	# Declare a global associated array that contains tag and commit hash pairs
	declare -g -A EXPECTEDRESULTS

	# v1.0.0
	CURRENTVERSION="1.0.0"
	AddSandboxTag $CURRENTVERSION

	# v1.0.1
	CURRENTVERSION=$(IncrementPatchVersion $CURRENTVERSION)
	AddSandboxTag $CURRENTVERSION
	TAGCOMMIT=$(GetSandboxLastCommit)
	RegisterMinorTagAlias $CURRENTVERSION $TAGCOMMIT

	# v1.1.0
	CURRENTVERSION=$(IncrementMinorVersion $CURRENTVERSION)
	AddSandboxTag $CURRENTVERSION

	# v1.1.1
	CURRENTVERSION=$(IncrementPatchVersion $CURRENTVERSION)
	AddSandboxTag $CURRENTVERSION
	TAGCOMMIT=$(GetSandboxLastCommit)
	RegisterMinorTagAlias $CURRENTVERSION $TAGCOMMIT

	# v1.2.0
	CURRENTVERSION=$(IncrementMinorVersion $CURRENTVERSION)
	AddSandboxTag $CURRENTVERSION
	TAGCOMMIT=$(GetSandboxLastCommit)
	RegisterMinorTagAlias $CURRENTVERSION $TAGCOMMIT
	RegisterMajorTagAlias $CURRENTVERSION $TAGCOMMIT

	# v2.0.0
	CURRENTVERSION=$(IncrementMajorVersion $CURRENTVERSION)
	AddSandboxTag $CURRENTVERSION

	# v2.0.1
	CURRENTVERSION=$(IncrementPatchVersion $CURRENTVERSION)
	AddSandboxTag $CURRENTVERSION

	# v2.0.2
	CURRENTVERSION=$(IncrementPatchVersion $CURRENTVERSION)
	AddSandboxTag $CURRENTVERSION
	TAGCOMMIT=$(GetSandboxLastCommit)
	RegisterMinorTagAlias $CURRENTVERSION $TAGCOMMIT
	RegisterMajorTagAlias $CURRENTVERSION $TAGCOMMIT
}

InitializeActualResults () {
	# Declare a global associated array that contains tag and commit hash pairs
	declare -g -A ACTUALRESULTS

	cd $SANDBOXFOLDER

	# Run the bash script
	bash "./${BASHSCRIPT}"
	# Read each command output line and split it by space into the tag name and the tag commit
	while read TAGNAME TAGCOMMIT; do
		# Consider the tag name as the associated array key and the tag commit as the key value
		ACTUALRESULTS["${TAGNAME}"]=$TAGCOMMIT
	# Launch 'git show-ref --tag' to get the combination of existing tags and their commit hashes 
	# Pipeline the result with 'awk '{print $2 " " $1}' to bring tags first and then the commit hashes
	# Pipeline the result with 'cut -d"/" -f3' to remove 'refs/tags/' from the beginning of the tags
	# Pipeline the result with 'cut -d"${VERSIONSYMBOL}" -f2' remove the version symbol from the beginning of the tags
	done < <( git show-ref --tag | awk '{print $2 " " $1}' | cut -d"/" -f3 | cut -d"${VERSIONSYMBOL}" -f2 )
	# Pop back the current directory
	cd ..
}

ValidateResults () {
	PASSED=true
	# Iterate over all the tag alias versions in the expected results dictionary
	for TAGALIASVERSION in "${!EXPECTEDRESULTS[@]}"; do
		# Fetch the expected commit hash that corresponds to the current tag alias version
		EXPECTEDCOMMIT=${EXPECTEDRESULTS[$TAGALIASVERSION]}
		# Fetch the actual commit hash that corresponds to the current tag alias version
		ACTUALCOMMIT=${ACTUALRESULTS[$TAGALIASVERSION]}

		if [ "${EXPECTEDCOMMIT}" == "${ACTUALCOMMIT}" ]; then
 			echo "$(tput setaf 2)[PASSED] $(tput setaf 7)${VERSIONSYMBOL}${TAGALIASVERSION} tag alias validation"
		else
			PASSED=false
			echo "$(tput setaf 1)[FAILED] $(tput setaf 7)${VERSIONSYMBOL}${TAGALIASVERSION} tag alias validation"
		fi
	done

	if [ $PASSED ]; then
		exit 0
	else
		exit 1
	fi
}

ConfigureGitUser

InitializeSandbox

InitializeExpectedResults

InitializeActualResults

ValidateResults