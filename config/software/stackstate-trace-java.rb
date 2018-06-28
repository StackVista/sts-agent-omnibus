name "stackstate-trace-java"
always_build true

process_sts_trace_java_apm_version = ENV['STS_TRACE_JAVA_APM_VERSION']
if process_sts_trace_java_apm_version.nil? || process_sts_trace_java_apm_version.empty?
    process_sts_trace_java_apm_version = "0.6.1B3"
end
default_version process_sts_trace_java_apm_version


build do
  jarfile = "sts-java-agent.jar"
  url = "https://github.com/StackVista/sts-trace-java/releases/download/v#{version}/sts-java-agent-#{version}.jar"
  command "curl #{url} -o #{jarfile}"
  command "mkdir -p #{install_dir}/trace-agent/jvm"
  command "mv #{jarfile} #{install_dir}/trace-agent/jvm"
end
