#!/bin/bash

# Github2eMail is a bash script that parses the GitHub API for projects you've
# starred and adds them to your rss2email configuration.
# The script will also delete projects it has added to your rss2email
# configuration if you're not starring them on GitHub anymore.

# Author : Antoine "CaptainArk" Joubert, 2018

# Function to clean temporary file
ExitCleanup() {
  if [[ ! -z ${TempFile} ]]; then
    [[ -f ${TempFile} ]] && rm ${TempFile}
  fi
}

trap ExitCleanup EXIT

# shellcheck source=config
source "$(dirname $0)/config"

# Checking if UserName has been defined
if [[ -z ${UserName} ]] || [[ $UserName == "changemeplease" ]]; then
  echo "GitHub username is incorrect of undefined in config file. Exiting..."
  exit 2
fi

GitHubApi="https://api.github.com/users/${UserName}/starred"
LastPage="$(curl -sI ${GitHubApi} | grep -Eo 'page=[[:digit:]]+' | tail -n1)"
TempFile=$(mktemp -t github2email.sh.XXXXXXXXXX)

# Checking for dependencies
for Dependencies in curl jq r2e; do
  if [[ ! -x $(which ${Dependencies}) ]]; then
    echo "${Dependencies} is required to run to script. Exiting..."
    exit 2
  fi
done

for StarPages in $(seq 1 ${LastPage#*=}); do
  curl -s "${GitHubApi}?page=${StarPages}" | jq -r '.[] | .name + "," + .html_url' | sed 's#$#/releases.atom#' >> ${TempFile}
done

# Checking for API request success
if [[ ! -s ${TempFile} ]]; then
  echo "Something went wrong while fetching the project starred list for ${UserName}. Exiting..."
  exit 2
fi

# Doing our magic stuff that does cool shit
for Star in $(cat ${TempFile}); do
  ProjectName=${Star%,*}
  ProjectUrl=${Star##*,}
  # Only add a project to r2e config if it does not already exist
  IsDeclaredProject="$(r2e list | grep ${ProjectUrl})"
  if [[ -z ${IsDeclaredProject} ]]; then
    r2e add g2e_${ProjectName} ${ProjectUrl}
    # We only want to be informed of future releases
    r2e run --no-send g2e_${ProjectName}
  echo "Project ${ProjectName} has been added to rss2email configuration !"
  fi
done

# Delete projects that were added to rss2email by this script but are no longer starred on GitHub
AddedProjects="$(r2e list | grep g2e_ | grep -Eo "https://github.com/.*/releases.atom")"
for Projects in ${AddedProjects}; do
  StillStaredProject="$(grep ${Projects} ${TempFile})"
  if [[ -z ${StillStaredProject} ]]; then
    ProjectToRemove="$(echo ${Projects} | cut -d'/' -f5)"
    r2e delete g2e_${ProjectToRemove}
    echo "Project ${ProjectToRemove} has been removed from rss2email configuration !"
  fi
done
