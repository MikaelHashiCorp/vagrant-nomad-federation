name = "usa-nomad"
data_dir = "/opt/nomad"

region = "usa"
datacenter = "usa-dc1"
log_level="DEBUG"

bind_addr = "192.168.56.72"

enable_debug=true

server {
  enabled = true
  bootstrap_expect = 1
  authoritative_region = "usa"
  server_join {  retry_join = [ "192.168.56.72", "192.168.56.71:4648" ]   retry_interval = "15s"}
  license_path = "/vagrant/lic/nomad.hclic"
}

plugin "raw_exec" {
    config {
        enabled = true
    }
}

client {
    enabled = true

    server_join {
      retry_join = ["192.168.56.72"]
    }
    # network_interface = "enp0s8"

    #  host_volume "consul_logs" {
    #     path = "/var/log/consul/"
    #     read_only = true
    # }
    # host_volume "docker.sock" {
    #     path = "/var/run/"
    #     read_only = true
    # }
    # host_volume "cgroups" {
    #     path = "/sys/fs/cgroup"
    #     read_only = true
    # }
    host_volume "proc" {
        path = "/proc/"
        read_only = true
    }
    
    options = {
      "docker.auth.config" = "/root/.docker/config.json"  # Used for Docker login credentials 
      "docker.volumes.enabled" = "true"
      "docker.privileged.enabled" = "true"
    }
}

# telemetry {
#   disable_hostname = "true"
#   collection_interval = "10s"
#   use_node_name = "false"
#   publish_allocation_metrics = "true"
#   publish_node_metrics = "true"
#   filter_default = "true"
#   prefix_filter = []
#   disable_dispatched_job_summary_metrics = "false"
#   statsite_address = ""
#   statsd_address = ""
#   # datadog_address = "localhost:8125"
#   datadog_tags = []
#   prometheus_metrics = "true"
# }
