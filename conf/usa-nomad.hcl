name = "usa-nomad"
datacenter = "usa-dc1"
data_dir = "/opt/nomad"
region = "usa"

bind_addr = "192.168.56.72"

enable_debug=true

server {
  enabled = true
  bootstrap_expect = 1
  authoritative_region = "emea"
  server_join {  retry_join = [ "192.168.56.72", "192.168.56.71:4648" ]   retry_interval = "5s"}
  license_path = "/vagrant/lic/nomad.hclic"
}

client {
  enabled = true
  server_join {
    retry_join = ["192.168.56.72"]
  }
}

plugin "raw_exec" {
    config {
        enabled = true
    }
}