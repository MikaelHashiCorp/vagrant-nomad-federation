job "volumes" {
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

  group "cache" {
    network {
      port "db" {
        to = 6379
      }
    }

    volume "proc" {
      type = "host"
      read_only = true
      source = "proc"
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:3.2"

        ports = ["db"]
      }

      volume_mount{
        volume = "proc"
        destination = "/proc/"
        read_only = true
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
