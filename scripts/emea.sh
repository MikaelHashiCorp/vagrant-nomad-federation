export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y zip unzip nginx jq

# install nomad ENTERPRISE manually
pushd /var/tmp
export NOMAD_VERSION="1.10.4"
curl -fsSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}+ent/nomad_${NOMAD_VERSION}+ent_linux_arm64.zip -o nomad.zip
# curl -fsSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_arm64.zip -o nomad.zip
unzip -o nomad.zip
sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad
chown root:root nomad
mv nomad /usr/bin/

# create directories
mkdir -p /opt/nomad
mkdir -p /etc/nomad.d

chmod 700 /opt/nomad
chmod 700 /etc/nomad.d

cp -ap /vagrant/conf/emea-nomad.hcl /etc/nomad.d/
chown -R nomad: /etc/nomad.d /opt/nomad/

cp -ap /vagrant/conf/nomad.service /etc/systemd/system/

systemctl enable nomad
systemctl start nomad


# ENVOY #
#########
curl -fsSL https://func-e.io/install.sh | bash -s -- -b /usr/local/bin
sudo cp `func-e which` /usr/local/bin

# consul
export CONSUL_VERSION="1.21.4"
# curl -fsSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_arm64.zip -o consul.zip
curl -fsSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}+ent/consul_${CONSUL_VERSION}+ent_linux_arm64.zip -o consul.zip
unzip -o consul.zip
useradd --system --home /etc/consul.d --shell /bin/false consul
chown root:root consul
mv consul /usr/bin/

# copy service config
cp -ap /vagrant/conf/consul.service /etc/systemd/system/consul.service

# create directories
mkdir --parents /etc/consul.d/
mkdir --parents /opt/consul/
chown --recursive consul:consul /etc/consul.d

# copy consul config
cp -ap /vagrant/conf/emea-consul.hcl /etc/consul.d/
chown -R consul:consul /etc/consul.d/ /opt/consul/
chmod 640 /etc/consul.d/*.hcl


systemctl enable consul
systemctl start consul


# optional liquidprompt #
#########################
apt-get install liquidprompt
liquidprompt_activate

# install docker
sudo apt-get update

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

# add auto completion for docker
sudo curl -fsSL https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
# sudo curl -fsSL https://github.com/docker/docker-ce/blob/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh

# docker post installation
usermod -aG docker nomad
usermod -aG docker vagrant

systemctl restart nomad


# Env variables and autocompletion
cp -ap /vagrant/conf/emea-env.sh /etc/profile.d/
alias env="env -0 | sort -z | tr '\0' '\n'"

# nginx
rm /var/www/html/index.nginx-debian.html
cp /vagrant/conf/nginx/index.html /var/www/html/
systemctl restart nginx

# code-server
curl -fsSL https://code-server.dev/install.sh | sh
cp /vagrant/conf/code-server.service /etc/systemd/system/             # copy systemd service
cp -R /vagrant/conf/code-server /home/vagrant/                        # copy code-server config
chown -R vagrant:vagrant /home/vagrant/code-server

# code-server is service
systemctl enable code-server
systemctl start code-server
