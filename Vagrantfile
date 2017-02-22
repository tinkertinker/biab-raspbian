Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.10"
  config.vm.synced_folder "./", "/vagrant"

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo apt-get -y install quilt qemu-user-static debootstrap pxz zip bsdtar
  	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
	. /home/vagrant/.nvm/nvm.sh
	nvm install v6.9.4
	nvm use v6.9.4
	sudo ln -s /home/vagrant/.nvm/versions/node/v6.9.4/bin/node /usr/bin/node
	sudo ln -s /home/vagrant/.nvm/versions/node/v6.9.4/bin/npm /usr/bin/npm
	mkdir -p /home/vagrant/work
	ln -s /home/vagrant/work /vagrant/work
  SHELL
end
