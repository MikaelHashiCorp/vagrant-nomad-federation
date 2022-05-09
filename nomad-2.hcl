datacenter = "dc1"
data_dir = "/opt/nomad/data"

bind_addr = "127.0.0.1"
advertise {
  http = "127.0.0.1:4646"
  rpc  = "127.0.0.1:4647"
  serf = "127.0.0.1:4648"
}

client {
    enabled = true
    # network_interface = "enp0s8"

    host_volume "docker.sock" {
        path = "/var/run/"
        read_only = true
    }
    host_volume "cgroups" {
        path = "/sys/fs/cgroup"
        read_only = true
    }
    host_volume "proc" {
        path = "/proc/"
        read_only = true
    }
    options = {
        "docker.auth.config" = "/root/.docker/config.json"
        "docker.volumes.enabled" = "true"
        "docker.privileged.enabled" = "true"
    }
   servers = ["127.0.0.1"]
}

consul {
  address = "127.0.0.1:8500"
  # If the configuration is separated for server and client nodes, the tag
  # "controlplane" should only be used on the server nodes.
  tags = ["controlplane"]
}

# vault {
#   enabled = true
#   address = "http://active.vault.service.consul:8200"
#   task_token_ttl = "1h"
#   create_from_role = "nomad-cluster"
#   token = "hvs.CAESICbnr7X8QykI-pM6k87LoarIH2g_50iTe9Y1y-_wMl00Gh4KHGh2cy52MFhzNjNPQXczSUxaNEJCR0lWU3VISXE"
# }

server {
  enabled = true
  # MUST be 16 bytes, Base64-encoded
  # encrypt = "LHFPLXFtSXJ0MmYucDFoZA=="
  bootstrap_expect = 1
#   server_join {
#     retry_join = ["192.168.56.21", "192.168.56.22", "192.168.56.23"]
#     retry_max = 3
#     retry_interval = "15s"
#   }
}

telemetry {
  # collection_interval = "1s"
  # disable_hostname = true
  prometheus_metrics = true
  # publish_allocation_metrics = true
  # publish_node_metrics = true
}

telemetry {
  disable_hostname = "true"
  collection_interval = "10s"
  use_node_name = "false"
  publish_allocation_metrics = "true"
  publish_node_metrics = "true"
  filter_default = "true"
  prefix_filter = []
  disable_dispatched_job_summary_metrics = "false"
  statsite_address = ""
  statsd_address = ""
  datadog_address = "localhost:8125"
  datadog_tags = []
  prometheus_metrics = "true"
}