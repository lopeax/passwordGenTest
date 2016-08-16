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

Visit http://passwordgen.test/generator/tests/test.php to view the tests or run these commands
```bash
vagrant ssh
php /vagrant/www/generator/tests/test.php
```
Note: the test.php file contains br tags, which will come up as characters when using command line
