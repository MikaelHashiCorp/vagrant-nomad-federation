export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y zip unzip nginx jq

# CONSUL CLIENT - for service discovery
export CONSUL_VERSION="1.21.4"
curl -fsSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}+ent/consul_${CONSUL_VERSION}+ent_linux_arm64.zip -o consul.zip
unzip -o consul.zip
useradd --system --home /etc/consul.d --shell /bin/false consul
chown root:root consul
mv consul /usr/bin/

cp -ap /vagrant/conf/consul.service /etc/systemd/system/consul.service

mkdir --parents /etc/consul.d/
mkdir --parents /opt/consul/
chown --recursive consul:consul /etc/consul.d

# Create Consul client config
cat > /etc/consul.d/consul-client.hcl <<EOF
node_name = "usa-client-2"
data_dir = "/opt/consul/"
datacenter = "usa-dc1"
license_path = "/vagrant/lic/consul.hclic"
server = false
bind_addr = "192.168.56.85"
client_addr = "127.0.0.1"
retry_join = ["192.168.56.81", "192.168.56.82", "192.168.56.83"]
connect {
  enabled = true
}
ports {
  grpc = 8502
}
EOF

chown -R consul:consul /etc/consul.d/ /opt/consul/
chmod 640 /etc/consul.d/*.hcl

systemctl enable consul
systemctl start consul

echo "Waiting for Consul to be ready..."
for i in {1..30}; do
  if curl -s -f http://127.0.0.1:8500/v1/status/leader > /dev/null 2>&1; then
    echo "Consul client is ready"
    break
  fi
  echo "Waiting for Consul... attempt $i/30"
  sleep 2
done

# NOMAD CLIENT ONLY
pushd /var/tmp
export NOMAD_VERSION="1.10.4"
curl -fsSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}+ent/nomad_${NOMAD_VERSION}+ent_linux_arm64.zip -o nomad.zip
unzip -o nomad.zip
sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad
chown root:root nomad
mv nomad /usr/bin/

mkdir -p /opt/nomad
mkdir -p /etc/nomad.d
mkdir -p /opt/alloc_mounts

chmod 700 /opt/nomad
chmod 700 /etc/nomad.d

cp -ap /vagrant/conf/usa-client-2-nomad.hcl /etc/nomad.d/
chown -R nomad: /etc/nomad.d /opt/nomad/ /opt/alloc_mounts

cp -ap /vagrant/conf/nomad.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable nomad
systemctl start nomad

sleep 10
echo "Checking Nomad service status..."
systemctl is-active --quiet nomad || (echo "Nomad service failed, attempting restart..." && systemctl restart nomad && sleep 5)

curl -fsSL https://func-e.io/install.sh | bash -s -- -b /usr/local/bin
sudo cp `func-e which` /usr/local/bin

apt-get install liquidprompt
liquidprompt_activate

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

usermod -aG docker nomad
usermod -aG docker vagrant

systemctl restart nomad

cp -ap /vagrant/conf/usa-client-2-env.sh /etc/profile.d/
alias env="env -0 | sort -z | tr '\0' '\n'"

# Made with Bob
