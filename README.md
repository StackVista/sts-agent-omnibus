StackState Agent - Omnibus Project
================

This is an [Omnibus](https://github.com/opscode/omnibus) project to build the StackState Agent packages.

It's using a [fork](https://github.com/chef/omnibus/compare/v4.0.0...DataDog:datadog-4.0.0) of the official 4.0.0 release of the Omnibus project.

## Build a package locally

* Install Docker

* Run the following script with the desired parameters

```bash
PLATFORM="deb-x64" # must be in "deb-x64", "deb-i386", "rpm-x64", "rpm-i386"
TRACE_AGENT_BRANCH="master" # Branch of the stackstate-trace-agent repo to use, default "master"
PROCESS_AGENT_BRANCH="master" # Branch of the datadog-process-agent repo to use, default "master"
AGENT_BRANCH="master" # Branch of sts-agent repo to use, default "master"
OMNIBUS_BRANCH="master" # Branch of sts-agent-omnibus repo to use, default "master"
AGENT_VERSION="5.4.0" # default to the latest tag on that branch
STS_TRACE_JAVA_APM_VERSION="0.6.1B3" # Stackstate APM client for Java
LOG_LEVEL="debug" # default to "info"
LOCAL_AGENT_REPO="~/sts-agent" # Path to a local repo of the agent to build from. Defaut is not set and the build will be done against the github repo

# The passphrase of the key you want to use to sign your .rpm package (if
# building an RPM package). If you don't set this variable, the RPM won't be
# signed but the build should succeed. Note that you must also mount a volume
# under /keys and bind it to a folder containing an RPM-SIGNING-KEY.private
# file containing your exported signing key. Finally, be aware that the
# package_maintainer DSL defined in config/projects/datadog_agent.rb and the
# full key name (My Name (comments) <my@email.com>) must match.
RPM_SIGNING_PASSPHRASE="my_super_secret_passphrase"

mkdir -p pkg
mkdir -p "cache/$PLATFORM"
docker run --name "sts-agent-build-$PLATFORM" \
  -e OMNIBUS_BRANCH=$OMNIBUS_BRANCH \
  -e LOG_LEVEL=$LOG_LEVEL \
  -e AGENT_BRANCH=$AGENT_BRANCH \
  -e AGENT_VERSION=$AGENT_VERSION \
  -e TRACE_AGENT_BRANCH=$TRACE_AGENT_BRANCH \
  -e PROCESS_AGENT_BRANCH=$PROCESS_AGENT_BRANCH \
  -e RPM_SIGNING_PASSPHRASE=$RPM_SIGNING_PASSPHRASE \
  -e LOCAL_AGENT_REPO=$LOCAL_AGENT_REPO # Only to use if you want to build from a local repo \
  -v `pwd`/pkg:/sts-agent-omnibus/pkg \
  -v `pwd`/keys:/keys \
  -v "`pwd`/cache/$PLATFORM:/var/cache/omnibus" \
  -v $LOCAL_AGENT_REPO:/dsts-agent-repo # Only to use if you want to build from a local repo \
  "stackstate/docker-sts-agent-build-$PLATFORM"

# Cleanup (necessary to launch another build)
docker rm sts-agent-build-$PLATFORM
```

## Build on Mac OS X

The Mac build platform should have:

* Xcode installed (type `git` in a terminal),
* [Go](http://golang.org/dl/) installed,
* sudoer rights for the build user,
* Bundler installed: `sudo gem install bundler`,
* Important directories created: `sudo mkdir -p /var/cache/omnibus /opt/stackstate-agent`,
* Owned by the right user: `sudo chown $USER:nogroup /var/cache/omnibus /opt/stackstate-agent`.
* Xcode license accepted (to sign package) `sudo xcodebuild -license`

Then run:
```bash
AGENT_BRANCH=<YOUR_AGENT_BRANCH> OMNIBUS_BRANCH=<YOUR_OMNIBUS_BRANCH> OMNIBUS_SOFTWARE_BRANCH=<YOUR_OMNIBUS_SOFTWARE_BRANCH> sh omnibus_build.sh
```
The env vars have the same meaning as the Dockerized build above. Omitting them will cause the default of `master` to be used for all 3
