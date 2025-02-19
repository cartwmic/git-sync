#!/usr/bin/env bash

GIT_SYNC_DIRECTORY="${GIT_SYNC_DIRECTORY:-$(pwd)}"
GIT_SYNC_COMMAND="${GIT_SYNC_COMMAND:-git-sync}"
GIT_SYNC_INTERVAL="${GIT_SYNC_INTERVAL:-500}"

# Initialize the directory
if [ ! -d  "$GIT_SYNC_DIRECTORY" ]; then
	if [ -z "$GIT_SYNC_REPOSITORY" ]; then
		echo "Please specify a value for GIT_SYNC_REPOSITORY in order to initialize the git repository"
		exit 1
	else
	    base="$(dirname $GIT_SYNC_DIRECTORY)"
		mkdir -p "$base"
		cd "$base"
		git clone "$GIT_SYNC_REPOSITORY" "$(basename $GIT_SYNC_DIRECTORY)"
	fi
fi

cd "$GIT_SYNC_DIRECTORY"

remote_name=$(git config --get branch.$(basename $(git symbolic-ref -q HEAD)).pushRemote)

echo "Syncing $(git remote get-url $remote_name) at $(pwd) with a default sync interval of $GIT_SYNC_INTERVAL"

while true; do
	changedFile=$(
	    gtimeout "$GIT_SYNC_INTERVAL" fswatch \
		--event Created \
		--event Updated \
		--event Removed \
		--event Renamed \
		--one-event \
		--latency 3 \
		--extended \
		--exclude '\.git' \
		--exclude '.*/\.#.+' \
		--recursive \
		--format "%f:%p%n" \
		"$GIT_SYNC_DIRECTORY" 2>/dev/null
	)
	if [ -z "$changedFile" ]
	then
		echo "Syncing due to timeout"
		$GIT_SYNC_COMMAND -n -s
	else
		echo "Syncing for: $changedFile"
		{ git check-ignore "$changedFile" > /dev/null; } || $GIT_SYNC_COMMAND -n -s
	fi
done
