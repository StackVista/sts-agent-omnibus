#!/bin/bash -e

set -o verbose

###########################
#
# WARNING: You need to rebuild the docker images if you do any changes to this file
#
############################

eval `ssh-agent -s`
ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts
ssh-add /sts-build-keys/id_rsa

export PROJECT_DIR=sts-agent-omnibus
export PROJECT_NAME=datadog-agent
export LOG_LEVEL=${LOG_LEVEL:-"info"}
export OMNIBUS_BRANCH=${OMNIBUS_BRANCH:-"master"}
export OMNIBUS_SOFTWARE_BRANCH=${OMNIBUS_SOFTWARE_BRANCH:-"master"}
export OMNIBUS_RUBY_BRANCH=${OMNIBUS_RUBY_BRANCH:-"datadog-5.0.0"}

set -e

# Clean up omnibus artifacts
rm -rf /var/cache/omnibus/pkg/*

# Clean up what we installed
rm -f /etc/init.d/stackstate-agent
rm -rf /etc/sts-agent
rm -rf /opt/$PROJECT_NAME/*

echo "Going into project dir"

cd $PROJECT_DIR

echo "Fetching dd-agent-omnibus-branch $OMNIBUS_BRANCH"

# Allow to use a different dd-agent-omnibus branch
git fetch --all

echo "Fetched dd-agent-omnibus-branch $OMNIBUS_BRANCH"

git checkout $OMNIBUS_BRANCH
git reset --hard origin/$OMNIBUS_BRANCH

# If an RPM_SIGNING_PASSPHRASE has been passed, let's import the signing key
if [ -n "$RPM_SIGNING_PASSPHRASE" ]; then
  gpg --import /keys/RPM-SIGNING-KEY.private
fi

# Last but not least, let's make sure that we rebuild the agent everytime because
# the extra package files are destroyed when the build container stops (we have
# to tweak omnibus-git-cache directly for that). Same for gohai and go-metro.
git --git-dir=/var/cache/omnibus/cache/git_cache/opt/stackstate-agent tag -d `git --git-dir=/var/cache/omnibus/cache/git_cache/opt/stackstate-agent tag -l | grep datadog-agent` || true
git --git-dir=/var/cache/omnibus/cache/git_cache/opt/stackstate-agent tag -d `git --git-dir=/var/cache/omnibus/cache/git_cache/opt/stackstate-agent tag -l | grep datadog-gohai` || true
git --git-dir=/var/cache/omnibus/cache/git_cache/opt/stackstate-agent tag -d `git --git-dir=/var/cache/omnibus/cache/git_cache/opt/stackstate-agent tag -l | grep datadog-metro` || true

# Install the gems we need, with stubs in bin/
bundle update # Make sure to update to the latest version of omnibus-software

bin/omnibus build -l=$LOG_LEVEL $PROJECT_NAME
