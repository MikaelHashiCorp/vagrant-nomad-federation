# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Abort if the vagrant-parallels plugin is not installed.
  unless Vagrant.has_plugin?("vagrant-parallels")
    raise "The vagrant-parallels plugin is not installed. Please run `vagrant plugin install vagrant-parallels`"
  end

  config.vm.box = "bento/ubuntu-24.04"

  # Set default provider to parallels
  ENV['VAGRANT_DEFAULT_PROVIDER'] = 'parallels'

  config.vm.provider "parallels" do |p|
    p.check_guest_tools = false
    p.update_guest_tools = false
    p.customize ["set", :id, "--adaptive-hypervisor", "on"]
  end

  # EMEA Region - 3 Nomad Servers + 2 Nomad Clients
  config.vm.define "emea-server-1" do |node|
    node.vm.hostname = "emea-server-1"
    node.vm.provision "shell", path: "scripts/emea-server-1.sh"
    node.vm.network "private_network", ip: "192.168.56.71"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "emea-server-2" do |node|
    node.vm.hostname = "emea-server-2"
    node.vm.provision "shell", path: "scripts/emea-server-2.sh"
    node.vm.network "private_network", ip: "192.168.56.72"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "emea-server-3" do |node|
    node.vm.hostname = "emea-server-3"
    node.vm.provision "shell", path: "scripts/emea-server-3.sh"
    node.vm.network "private_network", ip: "192.168.56.73"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "emea-client-1" do |node|
    node.vm.hostname = "emea-client-1"
    node.vm.provision "shell", path: "scripts/emea-client-1.sh"
    node.vm.network "private_network", ip: "192.168.56.74"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "emea-client-2" do |node|
    node.vm.hostname = "emea-client-2"
    node.vm.provision "shell", path: "scripts/emea-client-2.sh"
    node.vm.network "private_network", ip: "192.168.56.75"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  # USA Region - 3 Nomad Servers + 2 Nomad Clients
  config.vm.define "usa-server-1" do |node|
    node.vm.hostname = "usa-server-1"
    node.vm.provision "shell", path: "scripts/usa-server-1.sh"
    node.vm.network "private_network", ip: "192.168.56.81"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "usa-server-2" do |node|
    node.vm.hostname = "usa-server-2"
    node.vm.provision "shell", path: "scripts/usa-server-2.sh"
    node.vm.network "private_network", ip: "192.168.56.82"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "usa-server-3" do |node|
    node.vm.hostname = "usa-server-3"
    node.vm.provision "shell", path: "scripts/usa-server-3.sh"
    node.vm.network "private_network", ip: "192.168.56.83"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "usa-client-1" do |node|
    node.vm.hostname = "usa-client-1"
    node.vm.provision "shell", path: "scripts/usa-client-1.sh"
    node.vm.network "private_network", ip: "192.168.56.84"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "usa-client-2" do |node|
    node.vm.hostname = "usa-client-2"
    node.vm.provision "shell", path: "scripts/usa-client-2.sh"
    node.vm.network "private_network", ip: "192.168.56.85"
    node.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

end