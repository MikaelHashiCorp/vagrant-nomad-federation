yum update
yum install -y \
    epel-release \
    zip \
    unzip \
    which \
    vim \
    ca-certificates \
    curl \
    gnupg \
    redhat-lsb-core \
    nginx

# install docker
sudo yum update

sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo yum -y install docker-ce docker-ce-cli containerd.io

# add auto completion for docker
sudo curl -fsSL https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
# sudo curl -fsSL https://github.com/docker/docker-ce/blob/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh

# docker post installation
usermod -aG docker nomad 
usermod -aG docker vagrant


# NOMAD OSS / ENTERPRISE manually
pushd /var/tmp
export NOMAD_VERSION="1.2.6"
# curl -fsSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
curl -fsSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}+ent/nomad_${NOMAD_VERSION}+ent_linux_amd64.zip -o nomad.zip
unzip nomad.zip
sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad
chown root:root nomad
mv nomad /usr/bin/

# create directories
mkdir -p /opt/nomad
mkdir -p /etc/nomad.d

chmod 700 /opt/nomad
chmod 700 /etc/nomad.d

cp -ap /vagrant/conf/usa-nomad.hcl /etc/nomad.d/
chown -R nomad: /etc/nomad.d /opt/nomad/

cp -ap /vagrant/conf/nomad.service /etc/systemd/system/

systemctl enable nomad
systemctl start nomad


# ENVOY #
#########
# curl -fsSL https://func-e.io/install.sh | bash -s -- -b /usr/local/bin
# sudo cp `func-e which` /usr/local/bin  # Error "/tmp/vagrant-shell: line 33: func-e: command not found"
# sudo $(func-e which)  # Error "/lib64/libc.so.6: version `GLIBC_2.18' not found (required by /home/vagrant/.func-e/versions/1.21.2/bin/envoy)"


# CONSUL OSS or ENTERPRISE manually
export CONSUL_VERSION="1.12.0"
curl -fsSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
# curl -fsSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}+ent/consul_${CONSUL_VERSION}+ent_linux_amd64.zip -o consul.zip
unzip consul.zip
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
cp -ap /vagrant/conf/usa-consul.hcl /etc/consul.d/
chown -R consul:consul /etc/consul.d/ /opt/consul/
chmod 640 /etc/consul.d/*.hcl

systemctl enable consul
systemctl start consul


# optional liquidprompt #
#########################
# yum install liquidprompt (Ubuntu only)
# liquidprompt_activate


# Env variables and autocompletion
cp -ap /vagrant/conf/emea-env.sh /etc/profile.d/


# nginx
rm /var/www/html/index.nginx-debian.html
mkdir --parents /var/www/html/
cp /vagrant/conf/nginx/index.html /var/www/html/
systemctl restart nginx

# code-server
curl -fsSL https://code-server.dev/install.sh | sh
cp /vagrant/conf/code-server.service /etc/systemd/system/             # copy systemd service
cp -R /vagrant/conf/code-server /home/vagrant/                        # copy code-server config

# code-server terraform extention
code-server --install-extension hashicorp.terraform --force --extensions-dir /home/vagrant/code-server/extensions

# code-server is service
systemctl enable code-server
systemctl start code-server

# Install and start Datadog
# DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=??????? DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"
# Log into Datadog via Okta and find host(s):  https://app.datadoghq.com/dashboard/lists/preset/2