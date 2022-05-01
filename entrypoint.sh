#!/bin/bash
# Enable console output
set -x

# Declare a read-only global symbol which each tag starts with
VERSIONSYMBOL="v"
readonly VERSIONSYMBOL

InstallDependencies () {
    # Install GIT, and OpenSSH packages
    apk add git openssh
}

ConfigureGitUser () {
    # Set Git user configuration
    git config --global user.name github-actions[bot]
    git config --global user.email github-actions[bot]@users.noreply.github.com
    
    # Add shared GitHub Workspace as exception due to CVE-2022-24765
    git config --global --add safe.directory /github/workspace
}

InitializeTagDictionary () {
	# Declare a global associated array that contains tag and commit hash pairs
	declare -g -A TAGDICTIONARY

	# Read each command output line and split it by space into the tag name and the tag commit
	while read TAGNAME TAGCOMMIT; do
		# Consider the tag name as the associated array key and the tag commit as the key value
		TAGDICTIONARY["${TAGNAME}"]=$TAGCOMMIT
	# Launch 'git show-ref --tag' to get the combination of existing tags and their commit hashes 
	# Pipeline the result with 'awk '{print $2 " " $1}' to bring tags first and then the commit hashes
	# Pipeline the result with 'cut -d"/" -f3' to remove 'refs/tags/' from the beginning of the tags
	# Pipeline the result with 'cut -d"${VERSIONSYMBOL}" -f2' remove the version symbol from the beginning of the tags
	done < <( git show-ref --tag | awk '{print $2 " " $1}' | cut -d"/" -f3 | cut -d"${VERSIONSYMBOL}" -f2 )
}

PushTag () {
	TAGVERSION=$1
	TAGNAME=$2
	TAGCOMMIT=$3

	# Check whether the tag alias exists or not
	if [ "${TAGDICTIONARY[$TAGVERSION]}" ]; then
		# Check whether the existing tag alias has the same commit hash or not
		if [ "${TAGDICTIONARY[$TAGVERSION]}" == "${TAGCOMMIT}" ]; then
			# Return immediately due to the equality of the existing commit hash and the requested one
			exit 0
		else
			# Delete the existing tag alias to add it again with the requested commit hash later
			git tag -d "${TAGNAME}"
			# Delete the tag alias from the remote repo if the test mode is not active
			if [ ! $TESTMODE ]; then
				git push --delete origin "${TAGNAME}" || exit 1
			fi
		fi
	fi

	# Add the tag alias with the requested commit hash
	git tag "${TAGNAME}" "${TAGCOMMIT}"
	# Add the tag alias to the remote repo if the test mode is not active
	if [ ! $TESTMODE ]; then
		git push origin "${TAGNAME}" || exit 1
	fi
}

AliasVersion () {
	VERSIONALIAS=$1

	# Concat the version symbol with the verion alias to obtain the tag alias
	TAGALIAS="${VERSIONSYMBOL}${VERSIONALIAS}"
	# Concat the tag alias with '.*' to obtain the tag pattern
	TAGPATTERN="${TAGALIAS}.*"
	# Declare a local array that contains the matches of the tag pattern
	TAGMATCHES=()
	# Launch 'git tag -l "${TAGPATTERN}' to get the existing tags starts with the tag pattern
	# Pipeline the result with 'cut -d"${VERSIONSYMBOL}" -f2' to remove the version symbol from the beginning of the tags
	# Pipeline the result with 'sort -r' to descendingly sort the tag matches
	# Map the descending sorted tag matches to the declared array
	mapfile -t TAGMATCHES < <( git tag -l "${TAGPATTERN}" | cut -d"${VERSIONSYMBOL}" -f2 | sort -r )
	# Fetch the latest tag according to its version 
	LATESTTAG="${TAGMATCHES}"
	# Fetch the latest tag commit hash
	TAGCOMMIT=${TAGDICTIONARY[$LATESTTAG]}

	# Push the tag alias for the latest version
	PushTag "${VERSIONALIAS}" "${TAGALIAS}" "${TAGCOMMIT}"
}

# Install dependencies and configure the GIT user if the test mode is not active
if [ ! $TESTMODE ]; then
	InstallDependencies

	ConfigureGitUser
fi

InitializeTagDictionary

# Declare a local array that contains the major verions based on the existing tags
MAJORVERSIONS=()
# Launch 'git tag' to get the existing tags
# Pipeline the result with 'cut -d"${VERSIONSYMBOL}" -f2' to remove the version symbol from the beginning of the tags
# Pipeline the result with 'cut -d"." -f1' to parse the major version
# Pipeline the result with 'sort' to sort the parsed major verions
# Pipeline the result with 'unique' to remove the similar major verions
# Map the unique major verions to the declared array
mapfile -t MAJORVERSIONS < <( git tag | cut -d"${VERSIONSYMBOL}" -f2 | cut -d"." -f1 | sort | uniq )

ls

# Interate over all the major verions
for MAJORVERSION in "${MAJORVERSIONS[@]}"; do
	AliasVersion "${MAJORVERSION}"

	# Declare a local array that contains the minor verions of the major version
	MINORVERSIONS=()
	# Concat the version symbol, the major verion, and  '.*' characters to obtain the pattern
	PATTERN="${VERSIONSYMBOL}${MAJORVERSION}.*"
	# Launch 'git tag -l "${PATTERN}' to get the existing tags starts with the pattern
	# Pipeline the result with 'cut -d"${VERSIONSYMBOL}" -f2' to remove the version symbol from the beginning of the tags
	# Pipeline the result with 'cut -d"." -f 1-2' to parse the major version (1) and the minor version (2)
	# Pipeline the result with 'sort' to sort the parsed major verions
	# Pipeline the result with 'unique' to remove the similar major verions
	# Map the unique major verions to the declared array
	mapfile -t MINORVERSIONS < <( git tag -l "${PATTERN}" | cut -d"${VERSIONSYMBOL}" -f2 | cut -d"." -f 1-2 | sort | uniq )

	# Interate over all the minor verions
	for MINORVERSION in "${MINORVERSIONS[@]}"; do
		AliasVersion "${MINORVERSION}"
	done
done
