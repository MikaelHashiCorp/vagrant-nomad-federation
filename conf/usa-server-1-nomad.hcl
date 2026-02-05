name = "usa-server-1"
data_dir = "/opt/nomad"

region = "usa"
datacenter = "usa-dc1"

bind_addr = "192.168.56.81"

enable_debug = true

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

consul {
  address = "192.168.56.81:8500"
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise = true
  server_auto_join = true
  client_auto_join = true
}

server {
  enabled = true
  bootstrap_expect = 3
  authoritative_region = "emea"
  server_join {
    retry_join = ["192.168.56.81:4648", "192.168.56.82:4648", "192.168.56.83:4648", "192.168.56.71:4648"]
    retry_interval = "5s"
  }
  license_path = "/vagrant/lic/nomad.hclic"
}

client {
  enabled = false
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