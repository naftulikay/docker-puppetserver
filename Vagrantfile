# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "bento/centos-7.2"

  # set the hostname
  config.vm.hostname = "centos7"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", type: "dhcp"

  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "4096"]
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "vagrant/playbook.yml"
  end
end
