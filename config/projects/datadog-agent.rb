require "./lib/ostools.rb"

name 'stackstate-agent'
maintainer 'StackState <info@stackstate.com>'
homepage 'http://www.stackstate.com'
install_dir '/opt/stackstate-agent'

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

  # SysVInit service file
  if redhat?
    extra_package_file '/etc/rc.d/init.d/stackstate-agent'
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

  # Linux-specific dependencies
  dependency 'procps-ng'
  dependency 'sysstat'
end

# Mac and Windows
if osx? or windows?
  dependency 'gui'
end

# ------------------------------------
# Dependencies
# ------------------------------------

# creates required build directories
dependency 'preparation'

# Agent dependencies
dependency 'boto'
dependency 'docker-py'
dependency 'ntplib'
dependency 'protobuf-py'
dependency 'pycrypto'
dependency 'pyopenssl'
dependency 'python-consul'
dependency 'python-etcd'
dependency 'pyyaml'
dependency 'simplejson'
dependency 'supervisor'
dependency 'tornado'
dependency 'uptime'
dependency 'uuid'
dependency 'zlib'

# Check dependencies
dependency 'adodbapi'
dependency 'beautifulsoup4'
dependency 'dnspython'
dependency 'httplib2'
dependency 'kafka-python'
dependency 'kazoo'
dependency 'paramiko'
dependency 'pg8000'
dependency 'psutil'
dependency 'psycopg2'
dependency 'pymongo'
dependency 'pymysql'
dependency 'pysnmp'
dependency 'python-gearman'
dependency 'python-memcached'
dependency 'python-redis'
dependency 'python-rrdtool'
dependency 'pyvmomi'
dependency 'requests'
dependency 'scandir'
dependency 'snakebite'
dependency 'pytz'
dependency 'python_algorithms'
dependency 'iso8601'

# Additional software
dependency 'datadogpy'

# datadog-gohai and datadog-metro are built last before datadog-agent since they should always
# be rebuilt (if put above, they would dirty the cache of the dependencies below
# and trigger a useless rebuild of many packages)
dependency 'datadog-gohai'
if linux? and ohai['kernel']['machine'] == 'x86_64'
  dependency 'datadog-metro'
end

# Datadog agent
dependency 'datadog-agent'

# version manifest file
dependency 'version-manifest'

exclude '\.git*'
exclude 'bundler\/git'
