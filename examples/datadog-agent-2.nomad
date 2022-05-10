job "datadog-agent-2" {

 multiregion {
    strategy {
      max_parallel = 1
      on_failure   = "fail_all"
    }
    # region "emea" {
    #   count       = 1
    #   datacenters = ["emea-dc1"]
    # }
    region "usa" {
      count       = 1
      datacenters = ["usa-dc1"]
    }
  }
 
  group "datadog" {
    network {
      port "trace"  {
        static = 8126
        to = 8126
      }
      port "statsd" {
        static = 8125
        to = 8125
      }
    }
    volume "consul_logs" {
      type = "host"
      read_only = true
      source = "consul_logs"
    }
    volume "cgroups" {
      type = "host"
      read_only = true
      source = "cgroups"
    }
    volume "docker.sock" {
      type = "host"
      read_only = true
      source = "docker.sock"
    }
    volume "proc" {
      type = "host"
      read_only = true
      source = "proc"
    }
    task "datadog-agent" {
      driver = "docker"
      template {
        data = <<EOH
## All options defined here are available to all instances.
#
init_config:
instances:
  - url: "${DATADOG_CONSUL}"
    disable_legacy_service_tag: true
logs:
  - type: file
    path: /var/log/consul/*.log
    source: consul
    tags: env:${ENVIRONMENT}, cluster_name:xpinc-nomad-${ENVIRONMENT}, tribe:tesouraria-nomad
        EOH

        destination = "local/conf.yaml"
      }
      template {
        data = <<EOH
# dogstatsd_mapper_cache_size: 1000  # default to 1000
dogstatsd_mapper_profiles:
  - name: consul
    prefix: "consul."
    mappings:
      - match: 'consul\.http\.([a-zA-Z]+)\.(.*)'
        match_type: "regex"
        name: "consul.http.request"
        tags:
          method: "$1"
          path: "$2"
      - match: 'consul\.raft\.replication\.appendEntries\.logs\.([0-9a-f-]+)'
        match_type: "regex"
        name: "consul.raft.replication.appendEntries.logs"
        tags:
          peer_id: "$1"
      - match: 'consul\.raft\.replication\.appendEntries\.rpc\.([0-9a-f-]+)'
        match_type: "regex"
        name: "consul.raft.replication.appendEntries.rpc"
        tags:
          peer_id: "$1"
      - match: 'consul\.raft\.replication\.heartbeat\.([0-9a-f-]+)'
        match_type: "regex"
        name: "consul.raft.replication.heartbeat"
        tags:
          peer_id: "$1"
logs_enabled: true
        EOH

        destination = "local/datadog.yaml"
      }
      config {
        image = "gcr.io/datadoghq/agent:7.32.3"
        ports = ["trace","statsd"]
        volumes = [
            "local:/etc/datadog-agent/conf.d/consul.d",
            "local:/etc/datadog-agent"
        ]
      }
      volume_mount{
        volume = "consul_logs"
        destination = "/var/log/consul/"
        read_only = true
      }
      volume_mount{
        volume = "cgroups"
        destination = "/sys/fs/cgroup"
        read_only = true
      }
      volume_mount{
        volume = "proc"
        destination = "/proc/"
        read_only = true
      }
      volume_mount{
        volume = "docker.sock"
        destination = "/var/run/docker.sock"
        read_only = true
      }
      service {
        name = "datadog-agent"
      tags = [
        "urlprefix-datadog-agent${DOMAIN}"
      ]
        port = "trace"
      }
      env {
        DD_API_KEY = "${DD_API_KEY}"
        DD_APM_ENABLED = true
        DD_LOGS_ENABLED = true
        DD_PROCESS_AGENT_ENABLED = true
        DD_DOGSTATSD_NON_LOCAL_TRAFFIC = true
        DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL = true
        DD_TAGS = "env:${ENVIRONMENT}, cluster_name:xpinc-nomad-${ENVIRONMENT}, tribe:tesouraria-nomad"
        DD_APM_IGNORE_RESOURCES = "GET health.*, GET /metrics.*"
        DD_CONTAINER_EXCLUDE="name:filebeat.* name:rabbit.* name:datadog-agent.*"
      }

      resources {
        cpu    = 600  # value in mhz
        memory = 300  # 1024
      }
    }
  }
}