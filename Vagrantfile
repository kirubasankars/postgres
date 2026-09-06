# frozen_string_literal: true

# Three Ubuntu 20.04 guests matching inventories/ha/hosts.yml.
#   vagrant up
#   ansible-playbook playbooks/site.yml

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.ssh.insert_key = false

  {
    "pg-zk-01" => "10.20.30.11",
    "pg-zk-02" => "10.20.30.12",
    "pg-zk-03" => "10.20.30.13"
  }.each do |name, ip|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: ip
      node.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.memory = 2048
        vb.cpus = 2
      end
    end
  end
end
