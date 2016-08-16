# PasswordGen Testing
Testing environment for PasswordGen


### Requirements
This uses a combination of a customized vagrant setup with virtualbox

Oracle VM VirtualBox https://www.virtualbox.org/

Vagrant https://www.vagrantup.com/downloads.html

Vagrant Plugins via this line
```bash
vagrant plugin install vagrant-cachier vagrant-hostmanager vagrant-triggers vagrant-vbguest
```

## Installation
Run
```bash
vagrant up
```

Then when the autoinstaller is finished run
Note: several UAC prompts may come up
```bash
vagrant hostsmanager
```

Then ssh into the machine
```bash
vagrant ssh
```

For testing run these commands after sshing to the box (or visit their relative links in the browser)
```bash
php /vagrant/www/generator/tests/defaults.php
php /vagrant/www/generator/tests/setLength.php
php /vagrant/www/generator/tests/setKeyspace.php
php /vagrant/www/generator/tests/setLengthAndSetKeyspace.php
```
