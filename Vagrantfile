Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.10"
  config.vm.synced_folder "./", "/vagrant"

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo apt-get -y install quilt qemu-user-static debootstrap pxz zip bsdtar
  	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
	. /home/vagrant/.nvm/nvm.sh
	nvm install v7.5.0
	nvm use v7.5.0
	sudo ln -s /home/vagrant/.nvm/versions/node/v7.5.0/bin/node /usr/bin/node
	sudo ln -s /home/vagrant/.nvm/versions/node/v7.5.0/bin/npm /usr/bin/npm
	mkdir -p /home/vagrant/work
	ln -s /home/vagrant/work /vagrant/work
  SHELL
end
