# vagrant-nomad-federation

# Topology
```
                                NOMAD FEDERATION

       vagrant ssh emea                           vagrant ssh usa
   ################################         ################################
   #                              #         #                              #
   #                              #         #                              #
   #     -------------------      #         #     -------------------      #
   #     |NOMAD-client&srv |      #         #     |NOMAD-client&srv |      #
   #     |     reg: emea   |      #         #     |    reg: emea    |      #
   #     |     dc: emea-dc1|      #         #     |    dc: usa-dc1 |      #
   #     -------------------      #         #     -------------------      #
   #                              #         #                              #
   #     -------------------      #         #     -------------------      #
   #     | CONSUL          |      #         #     | CONSUL          |      #
   #     |                 |      #         #     |                 |      #
   #     |     dc: emea    |      #         #     |     dc: usa     |      #
   #     -------------------      #         #     -------------------      #
   #                 192.168.56.71#         #                 192.168.56.72#
   ################################         ################################

```
Main portal: 
- http://192.168.56.71 or
- http://192.168.56.72

EMEA
- nomad: http://192.168.56.71:4646 \
- consul: http://192.168.56.71:8500 \ 
- VScode: http://192.168.56.71:3000

USA
- nomad: http://192.168.56.72:4646 \
- consul: http://192.168.56.72:8500 \
- VScode: http://192.168.56.72:3000


# How to use this repo
Clone and cd into repo
```
git clone git@github.com:ion-training/vagrant-nomad-federation.git
```
```
cd vagrant-nomad-federation
```

Create lic/nomad.hclic and place license in it
```
touch lic/nomad.hclic
```

Create the lab
```
vagrant up
```

SSH into vm
```
vagrant ssh emea
```
```
vagrant ssh usa
```

Optional. SSH config for vscode remote explorer
```
vagrant ssh-config
```
# Confirm federation
```
nomad server members
```
```
consul members -wan
```
# Federation confirmation output
```
vagrant@emea:/vagrant/examples$ nomad server members
Name             Address        Port  Status  Leader  Protocol  Build      Datacenter  Region
emea-nomad.emea  192.168.56.71  4648  alive   true    2         1.2.6+ent  emea-dc1    emea
usa-nomad.usa    192.168.56.72  4648  alive   true    2         1.2.6+ent  usa-dc1     usa

vagrant@emea:/vagrant/examples$ consul members -wan
Node              Address             Status  Type    Build   Protocol  DC    Partition  Segment
emea-consul.emea  192.168.56.71:8302  alive   server  1.11.4  2         emea  default    <all>
usa-consul.usa    192.168.56.72:8302  alive   server  1.11.4  2         usa   default    <all>
```
# Job run multiregion
In the /vagrant/examples directory:
```
nomad job run redis-multi-region.nomad
```

redis-multi-region.nomad:
```
job "redis-multi-region" {

  multiregion {
    region "emea" {
      count       = 1
      datacenters = ["emea-dc1"]
    }

    region "usa" {
      count       = 1
      datacenters = ["usa-dc1"]
    }
  }

  type = "service"

  group "cache" {
    count = 1
    
    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:3.2"

        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
```

# Multiregion job status per region
```
nomad job status -region emea 
```
```
nomad job status -region usa
```
```
nomad job status -region emea redis-multi-region
```
```
nomad job status -region usa redis-multi-region
```

# Multiregion sample output
```
pc-workstation$ vagrant ssh emea
vagrant@emea:/vagrant/examples$ nomad job run redis-multi-region.nomad 
Job registration successful
Evaluation ID: e2263694-ac5d-c5d7-ff72-30e2584aef9c
vagrant@emea:/vagrant/examples$ nomad job status -region emea 
ID                  Type     Priority  Status   Submit Date
redis-multi-region  service  50        running  2022-02-14T08:16:06Z
vagrant@emea:/vagrant/examples$ 
vagrant@emea:/vagrant/examples$ nomad job status -region usa
ID                  Type     Priority  Status   Submit Date
redis-multi-region  service  50        running  2022-02-14T08:16:05Z
vagrant@emea:/vagrant/examples$ 
vagrant@emea:/vagrant/examples$ nomad job status -region emea redis-multi-region
ID            = redis-multi-region
Name          = redis-multi-region
Submit Date   = 2022-02-14T08:16:06Z
Type          = service
Priority      = 50
Datacenters   = emea-dc1
Namespace     = default
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
cache       0       0         1        0       0         0

Latest Deployment
ID          = 423dae3c
Status      = successful
Description = Deployment completed successfully

Multiregion Deployment
Region  ID        Status
emea    423dae3c  successful
usa     5b5a0290  successful

Deployed
Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
cache       1        1       1        0          2022-02-14T08:26:22Z

Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created  Modified
7945539f  4d2ce6be  cache       0        run      running  31s ago  15s ago
vagrant@emea:/vagrant/examples$ 
vagrant@emea:/vagrant/examples$ 
vagrant@emea:/vagrant/examples$ nomad job status -region usa redis-multi-region
ID            = redis-multi-region
Name          = redis-multi-region
Submit Date   = 2022-02-14T08:16:05Z
Type          = service
Priority      = 50
Datacenters   = usa-dc1
Namespace     = default
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
cache       0       0         1        0       0         0

Latest Deployment
ID          = 5b5a0290
Status      = successful
Description = Deployment completed successfully

Multiregion Deployment
Region  ID        Status
emea    423dae3c  successful
usa     5b5a0290  successful

Deployed
Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
cache       1        1       1        0          2022-02-14T08:26:22Z

Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created  Modified
966510e1  e32af496  cache       0        run      running  42s ago  26s ago
vagrant@emea:/vagrant/examples$ 

vagrant@emea:/vagrant/examples$ consul members 
Node         Address             Status  Type    Build   Protocol  DC    Partition  Segment
emea-consul  192.168.56.71:8301  alive   server  1.11.2  2         emea  default    <all>
vagrant@emea:/vagrant/examples$ 

vagrant@emea:/vagrant/examples$ consul members -wan
Node              Address             Status  Type    Build   Protocol  DC    Partition  Segment
emea-consul.emea  192.168.56.71:8302  alive   server  1.11.2  2         emea  default    <all>
usa-consul.usa    192.168.56.72:8302  alive   server  1.11.2  2         usa   default    <all>
vagrant@emea:/vagrant/examples$ 
```
# Job run client2-svc2
This job will create a Consul service called `client2-svc2` with tags `["${NOMAD_ALLOC_INDEX}", "${NOMAD_ALLOC_ID}"]`.  The purpose of this Consul service in a Docker container is to test DNS communication.

In the /vagrant/examples directory:
```
nomad job run client2-svc2.nomad
```
client2-svc2.nomad:
```
job "client2-svc2" {
  datacenters = ["emea-dc1"]

  group "svc2" {
    network {
      port "test" {
        to = 9090
      }
    }

    service {
      name = "client2-svc2"
      tags = ["${NOMAD_ALLOC_INDEX}", "${NOMAD_ALLOC_ID}"]
      port = 9090
      
    }

    task "svc2" {
      driver = "docker"

      config {
        image = "nicholasjackson/fake-service:v0.7.8"
      }

      env {
        MESSAGE = "hello from svc2 in DC ${ datacenter }"
      }

      resources {
        cpu    = 100
        memory = 100
      }
    }
  }
}
```
# Client2-svc2 Job status & DNS test
```
nomad job status -region emea client2-svc2
```
```
dig @127.0.0.1 -p 8600 0.client2-svc2.service.emea.consul
```
# Client2-svc2 sample output
```
vagrant@usa:/vagrant/examples$ nomad job status -region emea client2-svc2
ID            = client2-svc2
Name          = client2-svc2
Submit Date   = 2022-03-25T21:30:40Z
Type          = service
Priority      = 50
Datacenters   = emea-dc1
Namespace     = default
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
svc2        0       0         1        0       0         0

Latest Deployment
ID          = 758a09e3
Status      = successful
Description = Deployment completed successfully

Deployed
Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
svc2        1        1       1        0          2022-03-25T21:40:55Z

Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created    Modified
5615483a  341429cd  svc2        0        run      running  5m25s ago  5m9s ago

vagrant@usa:/vagrant/examples$ dig @127.0.0.1 -p 8600 0.client2-svc2.service.emea.consul

; <<>> DiG 9.16.1-Ubuntu <<>> @127.0.0.1 -p 8600 0.client2-svc2.service.emea.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41739
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;0.client2-svc2.service.emea.consul. IN	A

;; ANSWER SECTION:
0.client2-svc2.service.emea.consul. 0 IN A	192.168.56.71

;; Query time: 8 msec
```
# Login as Root
You should now be able to SSH as both `vagrant` and `root`:
```
$ vagrant ssh
You are now logged into your VM as 'vagrant'.
$ ssh root@localhost
You are now logged into your VM as 'root'.
# whoami
root
# pwd
/root
# exit
You are now back to your VM as 'vagrant'.
$ exit
You are now back on your host machine.
$
```
