require "./lib/ostools.rb"

name 'stackstate-agent'
if windows?
  # Windows doesn't want our e-mail address :(
  maintainer 'StackState'
else
  maintainer 'StackState <info@stackstate.com>'
end
homepage 'http://www.stackstate.com'

if ohai['platform'] == "windows"
  # Note: this is not the final install dir, not even the default one, just a convenient
  # spaceless dir in which the agent will be built.
  # Omnibus doesn't quote the Git commands it launches unfortunately, which makes it impossible
  # to put a space here...
  install_dir "C:/opt/stackstate-agent/"
else
  install_dir '/opt/stackstate-agent'
end

build_version do
  source :git, from_dependency: 'datadog-agent'
  output_format :dd_agent_format
end

build_iteration 1

description 'StackState Monitoring Agent
 The StackState Monitoring Agent is a lightweight process that monitors system
 processes and services, and sends information to StackState.
 .
 This package installs and runs the advanced Agent daemon, which queues and
 forwards metrics from your applications as well as system services.
 .
 See http://www.stackstate.com/ for more information
'

# ------------------------------------
# Generic package information
# ------------------------------------

# .deb specific flags
package :deb do
  vendor 'StackState <info@stackstate.com>'
  epoch 1
  license 'Simplified BSD License'
  section 'utils'
  priority 'extra'
end

# .rpm specific flags
package :rpm do
  vendor 'StackState <info@stackstate.com>'
  epoch 1
  dist_tag ''
  license 'Simplified BSD License'
  category 'System Environment/Daemons'
  priority 'extra'
  if ENV.has_key?('RPM_SIGNING_PASSPHRASE') and not ENV['RPM_SIGNING_PASSPHRASE'].empty?
    signing_passphrase "#{ENV['RPM_SIGNING_PASSPHRASE']}"
  end
end

if redhat?
  runtime_dependency 'initscripts'
end

# OSX .pkg specific flags
package :pkg do
  identifier 'com.datadoghq.agent'
  signing_identity 'Developer ID Installer: Datadog, Inc. (JKFCB4CN7C)'
end
compress :dmg do
  window_bounds '200, 200, 750, 600'
  pkg_position '10, 10'
end

# Windows .msi specific flags
package :msi do
  # previous upgrade code was used for older installs, and generated
  # per-user installs.  Changing upgrade code, and switching to
  # per-machine
  per_user_upgrade_code = '82210ed1-bbe4-4051-aa15-002ea31dde15'

  # For a consistent package management, please NEVER change this code
  upgrade_code '0c50421b-aefb-4f15-a809-7af256d608a5'
  bundle_msi true
  bundle_theme true
  wix_candle_extension 'WixUtilExtension'
  wix_light_extension 'WixUtilExtension'
  if ENV['SIGN_WINDOWS']
    signing_identity "ECCDAE36FDCB654D2CBAB3E8975AA55469F96E4C", machine_store: true, algorithm: "SHA256"
  end
  parameters({
    'InstallDir' => install_dir,
    'InstallFiles' => "#{Omnibus::Config.source_dir()}/datadog-agent/sts-agent/packaging/datadog-agent/win32/install_files",
    'DistFiles' => "#{Omnibus::Config.source_dir()}/datadog-agent/sts-agent/dist",
    'PerUserUpgradeCode' => per_user_upgrade_code
  })
end
# Note: this is to try to avoid issues when upgrading from an
# old version of the agent which shipped also a datadog-agent-base
# package.
if redhat?
  replace 'stackstate-agent-base < 5.0.0'
  replace 'stackstate-agent-lib < 5.0.0'
elsif debian?
  replace 'stackstate-agent-base (<< 5.0.0)'
  replace 'stackstate-agent-lib (<< 5.0.0)'
  conflict 'stackstate-agent-base (<< 5.0.0)'
  # needed starting debian 9
  runtime_dependency 'gnupg'
end

# ------------------------------------
# OS specific DSLs and dependencies
# ------------------------------------

# Linux
if linux?
  # Debian
  if debian?
    extra_package_file '/etc/init.d/stackstate-agent'
    extra_package_file '/lib/systemd/system/stackstate-agent.service'
  end

  if redhat?
    extra_package_file '/etc/rc.d/init.d/stackstate-agent'
    extra_package_file '/usr/lib/systemd/system/stackstate-agent.service'

  end

  if suse?
    extra_package_file '/etc/init.d/stackstate-agent'
    extra_package_file '/usr/lib/systemd/system/stackstate-agent.service'
  end

  # connbeat, specific to linux
  extra_package_file '/etc/sts-agent/connbeat.yml'
  dependency 'connbeat'

  # Supervisord config file for the agent
  extra_package_file '/etc/sts-agent/supervisor.conf'

  # Example configuration files for the agent and the checks
  extra_package_file '/etc/sts-agent/stackstate.conf.example'
  extra_package_file '/etc/sts-agent/conf.d'

  # Custom checks directory
  extra_package_file '/etc/sts-agent/checks.d'

  # Just a dummy file that needs to be in the RPM package list if we don't want it to be removed
  # during RPM upgrades. (the old files from the RPM file listthat are not in the new RPM file
  # list will get removed, that's why we need this one here)
  extra_package_file '/usr/bin/sts-agent'
end

# creates required build directories - has to be the first declared dep
dependency 'preparation'


if not windows?
  # Additional software
  dependency 'datadogpy'
end

# datadog-gohai, datadog-metro and stackstate-trace-agent
# are built last before datadog-agent since they should always be rebuilt
# (if put above, they would dirty the cache of the dependencies below
# and trigger a useless rebuild of many packages)
if not osx?
  dependency 'datadog-gohai'
end

if linux? and ohai['kernel']['machine'] == 'x86_64'
  dependency 'datadog-metro'
end

if windows?
  dependency 'datadog-upgrade-helper'
end
if linux?
  # not supported anymore for agent v1
  # dependency 'stackstate-trace-agent'
  dependency 'datadog-process-agent'
end

# Stackstate trace java jar and not supported for agent v1
# dependency 'stackstate-trace-java'

# Datadog agent
dependency 'datadog-agent'
dependency 'datadog-agent-integrations'

# Remove pyc/pyo files from package
# should be built after all the other python-related software defs
if linux?
  dependency 'py-compiled-cleanup'
end

# version manifest file
# should be built after all the other dependencies
dependency 'version-manifest'

exclude '\.git*'
exclude 'bundler\/git'
