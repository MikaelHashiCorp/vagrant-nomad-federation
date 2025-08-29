acl = "write"
key "consul-snapshot/lock" {
  policy = "write"
}
session "server-1234" {
  policy = "write"
}
service "consul-snapshot" {
  policy = "write"
}
