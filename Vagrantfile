# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.9"

  config.vm.define "emea" do |emea|
    emea.vm.hostname = "emea"
    emea.vm.provision "shell", path: "scripts/emea.sh"
    emea.vm.provision "shell", path: "scripts/setup_ssh.sh"
    emea.vm.network "private_network", ip: "192.168.56.71"
    emea.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

  config.vm.define "usa" do |usa|
    usa.vm.hostname = "usa"
    usa.vm.provision "shell", path: "scripts/usa.sh"
    usa.vm.provision "shell", path: "scripts/setup_ssh.sh"
    usa.vm.network "private_network", ip: "192.168.56.72"
    usa.ssh.extra_args = ["-t", "cd /vagrant/examples/; bash --login"]
  end

end