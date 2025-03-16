#!/usr/bin/env bash

# Set safer defaults, do not proceed past unhandled errors
set -e          # Exit the script in any command has a non-zero exit status
set -u          # Do not allow use of undefined variables
set -x          # Print the command about to be run fully expanded before running it
set -o pipefail # If any command in a pipe chain fails, the exit of the whole command fails
IFS=$'\n\t'     # Set a more sensible field separator

# Easily debug the script with this special PS4 prompt
PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

dot() {
	/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"
}

# Move to the home directory
cd ~/ || exit

# Get the file we want to open
fileToOpen="$(dot ls-tree HEAD -r --full-name --full-tree | awk '{print $4}' | fzf --preview='bat --style=numbers --color=always {}')"
echo "$fileToOpen"

# If no file is chosen then exit
if [[ -z "$fileToOpen" ]]; then
	exit 1
fi

# Open the file
nvim "$fileToOpen"
