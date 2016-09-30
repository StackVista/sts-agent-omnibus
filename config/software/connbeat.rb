name "connbeat"

default_version "0.0.1"

connbeat_dir = ENV['CONNBEAT_DIST_DIR']
if connbeat_dir.nil? || connbeat_dir.empty?
  abort("Expecting CONNBEAT_DIST_DIR that points to Connection Beat distribution.")
end

build do
  ship_license "https://github.com/raboof/connbeat/blob/master/LICENSE.md"
  copy "#{connbeat_dir}/linux/connbeat", '/opt/stackstate-agent/bin'
end
