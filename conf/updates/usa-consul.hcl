node_name = "usa-consul"
data_dir = "/opt/consul/"

datacenter = "usa"

# license_path = "/vagrant/lic/consul.hclic"

server = true

bootstrap_expect = 1

ui_config {
    enabled = true
}

bind_addr = "192.168.56.72"
client_addr = "0.0.0.0"

retry_join = ["192.168.56.72"]
retry_join_wan = ["192.168.56.71"]

connect {
  enabled = true
}

ports {
  grpc = 8502
}
