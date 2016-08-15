#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/../.."

################################################################################
# On guest VM or host machine:
# Upload the current branch to both the staging site and to GitLab.
################################################################################

source "scripts/_includes/colors.sh"
source "scripts/deploy/_config.sh"

#---------------------------------------
# GitLab
#---------------------------------------

green bold "Deploying to origin ($(git config remote.origin.url))..."
git push origin HEAD
echo

#---------------------------------------
# Staging
#---------------------------------------

green bold "Deploying to staging ($(git config remote.staging.url))..."
git push staging HEAD
