name = "emea-nomad"
data_dir = "/opt/nomad"

region = "emea"
datacenter = "emea-dc1"

bind_addr = "192.168.56.71"

enable_debug = true

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

consul {
  address = "192.168.56.71:8500"
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise = true
  server_auto_join = true
  client_auto_join = true
}

server {
  enabled = true
  bootstrap_expect = 1
  authoritative_region = "emea"
  server_join {
    retry_join = ["192.168.56.71:4648"]
    retry_interval = "5s"
  }
  license_path = "/vagrant/lic/nomad.hclic"
}

client {
  enabled = true
  server_join {
    retry_join = ["192.168.56.71:4648"]
  }
}

plugin "docker" {
  config {
    allow_privileged = true
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}