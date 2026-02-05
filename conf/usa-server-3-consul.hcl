node_name = "usa-server-3"
data_dir = "/opt/consul/"

datacenter = "usa-dc1"

license_path = "/vagrant/lic/consul.hclic"

server = true

bootstrap_expect = 3

ui_config {
    enabled = true
}

bind_addr = "192.168.56.83"
client_addr = "0.0.0.0"

retry_join = ["192.168.56.81", "192.168.56.82", "192.168.56.83"]
retry_join_wan = ["192.168.56.71", "192.168.56.72", "192.168.56.73"]

connect {
  enabled = true
}

ports {
  grpc = 8502
}