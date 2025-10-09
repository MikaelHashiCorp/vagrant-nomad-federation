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

  config.vm.define "emea" do |emea|
    emea.vm.hostname = "emea"
    emea.vm.provision "shell", path: "scripts/emea.sh"
    emea.vm.network "private_network", ip: "192.168.56.71"
    emea.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "usa" do |usa|
    usa.vm.hostname = "usa"
    usa.vm.provision "shell", path: "scripts/usa.sh"
    usa.vm.network "private_network", ip: "192.168.56.72"
    usa.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

end