#!/bin/bash

# shellcheck source=config
source "$(dirname $0)/config"

# Checking if UserName has been defined
if [[ -z ${UserName} ]] || [[ $UserName == "changemeplease" ]]; then
  echo "GitHub username is incorrect of undefined in config file. Exiting..."
fi

GitHubApi="https://api.github.com/users/${UserName}/starred"
StarredList=$(curl -s ${GitHubApi} | jq -r '.[] | .name + "," + .html_url' | sed 's#$#/releases.atom#')

# Checking for API request success
if [[ -z ${StarredList} ]]; then
  echo "Something went wrong while fetching the project starred list for ${UserName}. Exiting..."
  exit 2
fi

# Checking for dependencies
for Dependencies in curl jq r2e; do
  if [[ ! -x $(which ${Dependencies}) ]]; then
    echo "${Dependencies} is required to run to script. Exiting..."
    exit 2
  fi
done

# Doing our magic stuff that does cool shit
for Star in ${StarredList}; do
  ProjectName=${Star%,*}
  ProjectUrl=${Star##*,}
  # Only add a project to r2e config if it does not already exist
  IsDeclaredProject="$(r2e list | grep ${ProjectUrl})"
  if [[ -z ${IsDeclaredProject} ]]; then
    r2e add ${ProjectName} ${ProjectUrl}
    # We only want to be informed of future releases
    r2e run --no-send ${ProjectName}
  echo "Project ${ProjectName} has been added to rss2email configuration !"
  fi
done
