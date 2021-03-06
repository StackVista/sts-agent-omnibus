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

PROJECT_DIR=sts-agent-omnibus
PROJECT_NAME=datadog-agent
LOG_LEVEL=${LOG_LEVEL:-"info"}
export AGENT_BRANCH=${AGENT_BRANCH:-"master"}
export STS_TRACE_JAVA_APM_VERSION=${STS_TRACE_JAVA_APM_VERSION:-"0.6.1B3"}
export OMNIBUS_BRANCH=${OMNIBUS_BRANCH:-"master"}
export OMNIBUS_SOFTWARE_BRANCH=${OMNIBUS_SOFTWARE_BRANCH:-"master"}
export OMNIBUS_RUBY_BRANCH=${OMNIBUS_RUBY_BRANCH:-"datadog-5.5.0"}
export INTEGRATIONS_CORE_BRANCH=${INTEGRATIONS_CORE_BRANCH:-"master"}

REMOTE_AGENT_REPO_RAW="https://raw.githubusercontent.com/StackVista/sts-agent"
LOCAL_DD_AGENT="/dd-agent-repo"

set -e

# Clean up omnibus artifacts
rm -rf /var/cache/omnibus/pkg/*

# Clean up what we installed
rm -f /etc/init.d/stackstate-agent
rm -rf /etc/sts-agent
rm -rf /opt/$PROJECT_NAME/*

builtin cd $PROJECT_DIR

# Allow to use a different dd-agent-omnibus branch
git fetch --all
git checkout $OMNIBUS_BRANCH
git reset --hard origin/$OMNIBUS_BRANCH


# If an RPM_SIGNING_PASSPHRASE has been passed, let's import the signing key
if [ -n "$RPM_SIGNING_PASSPHRASE" ]; then
  gpg --import /keys/RPM-SIGNING-KEY.private
fi

# NOTE: JMX_VERSION plays no role <5.14.x (jmx bundled with agent)
# If "current" JMX version, set it from the corresponding agent branch config.py
if [ -n "$LOCAL_AGENT_REPO" ]; then
  cd $LOCAL_DD_AGENT
  JMX_VERSION=$(git show $AGENT_BRANCH:config.py | grep 'JMX_VERSION' | cut -f2 -d'=' | tr -d ' "')
  cd -
else
  JMX_VERSION=$(curl -v $REMOTE_AGENT_REPO_RAW/$AGENT_BRANCH/config.py 2>/dev/null | grep 'JMX_VERSION' | cut -f2 -d'=' | tr -d ' "')
fi
export JMX_VERSION

# Install the gems we need, with stubs in bin/
bundle update # Make sure to update to the latest version of omnibus-software

bin/omnibus build -l=$LOG_LEVEL $PROJECT_NAME
