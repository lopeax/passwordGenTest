# Configure the Vagrant VM
# Documentation: http://docs.vagrantup.com/v2/vagrantfile/
Vagrant.configure(2) do |config|

  __dir__ = File.dirname(__FILE__)

  #===============================================================================
  # Settings
  #===============================================================================

  #---------------------------------------
  # Hostnames
  #---------------------------------------

  # PRIMARY HOSTNAME
  # We use ".test" as the TLD because it's reserved by IETF for internal use
  #   (https://en.wikipedia.org/wiki/.test)
  # The other options ".example", ".localhost" and ".invalid" aren't as good
  #   (https://tools.ietf.org/html/rfc2606)
  # Some people use ".dev", but it is now allocated to Google
  #   (http://www.theregister.co.uk/2015/03/13/google_developer_gtld_domain_icann/)
  # Also ".vm", which is not assigned yet, but it could be in the future
  # And there's ".local" which is reserved for Bonjour
  #   (https://en.wikipedia.org/wiki/.local)
  # Another option would be to use our own domain (.vm.alberon.co.uk) - but that's rather long
  # Or we could register our own short domain specially - but that's unnecessary
  hostname = 'passwordgen.test'

  # Now run the initial setup, in case we need to change the hostname before
  # we set up the aliases below
  check_setup(hostname)

  # HOSTNAME ALIASES
  # Set additional hostnames here. These can be subdomains or they can be
  # completely separate domain names, but as above I recommend that they end
  # with ".test". They will be added to the hosts files on the host and guest
  # machines. You will also need set up Apache vhosts using Ansible.
  hostname_aliases = [
    "www.#{hostname}",            # Main site
    "pma.#{hostname}",            # phpMyAdmin
    "mail.#{hostname}",           # Roundcube mail client
    "logs.#{hostname}",           # Log viewer
    "ngrok.#{hostname}",          # ngrok (tunnel) logs
    # Add custom aliases here...

  ]

  #---------------------------------------
  # Synced folders
  #---------------------------------------

  # SYNCED FOLDER MODE
  # 1. :default - This is the most stable but can be slow and doesn't support
  #               long filenames (>260 characters).
  # 2. :long    - This supports long filenames but doesn't work on VirtualBox
  #               5.0.0 (and maybe later versions).
  # 3. :nfs     - This is faster but less reliable. It sometimes has to be
  #               restarted manually, and I've had problems with Gulp (Error:
  #               EIO, rmdir '/vagrant/www/css'). It also doesn't support long
  #               filenames, and it doesn't support 'mount_options'.
  sync_mode = :default

  # MOUNT OPTIONS
  # Normally we want to change permissions on the default folder from 777 to 775
  # to match the live servers and also prevent 'ls' highlighting all directories
  # in green to warn about them being world-writable. (Unfortunately there's
  # nothing we can do about the files all being executable without breaking
  # scripts.) Sometimes you may need to change this back to 777 - e.g. if using
  # mod_php instead of suPHP.
  mount_options = 'dmode=775,fmode=775'

  # BIND DIRECTORIES
  # Here you can set sub-directories that need to be on the *real* Linux
  # filesystem, not the shared folder - either for speed (e.g. cache files) or
  # because they have very long filenames (> 260 characters). They are not
  # shared with the host machine, so they can't be edited by the user very
  # easily, and they mustn't be in the Git repository, as the host machine will
  # appear out of sync with the guest (VM).
  binds = {
    # ***
    # WARNING: Make sure these directories are ignored by Git!
    # ***

    # npm sometimes creates very long directory names
    # https://github.com/npm/npm/issues/3670
    # '/vagrant/node_modules' => '/srv/node_modules',
  }

  #---------------------------------------
  # Virtual hardware
  #---------------------------------------

  # RAM
  memory_size = 2 * 1024 # MB

  # Number of CPUs
  cpu_count = 2

  # CPU usage cap
  cpu_cap = 80 # %

  #===============================================================================
  # Hostnames
  #===============================================================================

  #---------------------------------------
  # Main hostname
  #---------------------------------------

  config.vm.hostname = hostname

  #---------------------------------------
  # Host Manager
  #---------------------------------------

  if Vagrant.has_plugin?('vagrant-hostmanager')

    config.hostmanager.aliases = hostname_aliases

    # Enable hostmanager on host and guest machines
    config.hostmanager.enabled     = true
    config.hostmanager.manage_host = true

    # Get the IP address assigned by DHCP, because Hostmanager sets it to 127.0.0.1 otherwise
    # https://github.com/smdahlen/vagrant-hostmanager/issues/118#issuecomment-57949554
    config.hostmanager.ignore_private_ip = true

    config.hostmanager.ip_resolver = proc do |machine|
      result = ''
      machine.communicate.execute('/sbin/ifconfig eth1') do |type, data|
        result << data if type == :stdout
      end
      (ip = /^\s*inet .*?(\d+\.\d+\.\d+\.\d+)\s+/.match(result)) && ip[1]
    end

  else
    puts '** Warning: Host Manager plugin is not installed - suggest you run:'
    puts '   vagrant plugin install vagrant-hostmanager'
    puts
  end

  #===============================================================================
  # Base box
  #===============================================================================

  # Ubuntu 14.04 LTS (Trusty Tahr) will be supported until April 2019
  # It is one of the easiest to configure operating systems, so we use it even
  # though it doesn't match our live servers (CentOS)
  config.vm.box = 'ubuntu/trusty64'

  #===============================================================================
  # Networking
  #===============================================================================

  # Set up a private network connection so we can connect on any port like it
  # was a regular server, but no-one else can (for security), and use an
  # automatically assigned IP address so we can run multiple VMs at once without
  # collisions (we can use the hostname to connect to it)
  config.vm.network 'private_network', type: 'dhcp'

  #===============================================================================
  # Synced folders
  #===============================================================================

  #---------------------------------------
  # NFS
  #---------------------------------------

  # Use NFS as it's faster than the default VirtualBox filesystem
  if sync_mode == :nfs
    if Vagrant::Util::Platform.windows? and not Vagrant.has_plugin?('vagrant-winnfsd')
      puts '** Warning: NFS is not supported - suggest you run:'
      puts '   vagrant plugin install vagrant-winnfsd'
      puts
      sync_mode = :default
    else

      config.vm.synced_folder '.', '/vagrant',
        nfs: true
        # Unfortunately there seems to be no way to set the filemode in NFS - this doesn't work:
        # mount_options: [mount_options]

      # Change owner to the 'vagrant' user & group
      # Warning: These are shared between *all* shares, so it's not possible to
      # have a different UID/GID on different VMs. If these are changed, "winnfsd.exe"
      # must be killed and the VM reloaded before they will take effect.
      if Vagrant.has_plugin?('vagrant-winnfsd')
        config.winnfsd.uid = 1000
        config.winnfsd.gid = 1000
      end

      # Currently disabled for cache folders because it seems to result in corrupt APT files
      # if Vagrant.has_plugin?('vagrant-cachier')
      #   config.cache.synced_folder_opts = {type: 'nfs'}
      # end

    end
  end

  #---------------------------------------
  # Long filename support
  #---------------------------------------

  # Workaround to allow long filenames, which npm generates sometimes
  # https://github.com/npm/npm/issues/3670#issuecomment-82825408
  # This was going to be added to Vagrant:
  # https://github.com/mitchellh/vagrant/pull/5495
  # But was then removed due to a bug:
  # https://github.com/mitchellh/vagrant/issues/5933
  # WARNING: This DOES NOT work in VirtualBox 5.0.0
  # But it does work in 4.3.x, and it may be fixed in later versions...
  if sync_mode == :long
    if Vagrant::Util::Platform.windows?

      # Disable the default share
      config.vm.synced_folder '.', '/vagrant', disabled: true

      # Create a new one using the "//?/" prefix to switch to increase the maximum path length
      # https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx#maxpath
      config.vm.provider 'virtualbox' do |vb|
        vb.customize [
          'sharedfolder', 'add', :id,
          '--name', 'vagrant',
          '--hostpath', ('//?/' + File.dirname(__FILE__)).gsub('\\','/')
        ]
      end

      # Now mount that new share instead
      config.vm.provision 'synced_folder',
        type: :shell,
        inline: "mkdir /vagrant 2>/dev/null; mount -t vboxsf -o uid=$(id -u vagrant),gid=$(getent group vagrant | cut -d: -f3),#{mount_options} vagrant /vagrant",
        run: 'always'

    else
      sync_mode = :default
    end
  end

  #---------------------------------------
  # Default - Vagrant Shared folders
  #---------------------------------------

  if sync_mode == :default

    # This is the simple option :-)
    config.vm.synced_folder '.', '/vagrant', mount_options: [mount_options]

  end

  #---------------------------------------
  # Binds (non-shared subfolders)
  #---------------------------------------

  # This script creates the two directories and binds them together
  binds.each do |dest, src|
    config.vm.provision "bind #{dest}",
      type: :shell,
      inline: "
        mkdir -p #{src} 2>/dev/null
        echo 'This directory is mounted inside the VM, not shared with the host' > '#{src}/! NOT SHARED.txt'
        chown vagrant:vagrant #{src}
        chmod 775 #{src}
        mkdir -p #{dest} 2>/dev/null
        echo 'This directory is mounted inside the VM, not shared with the host' > '#{dest}/! NOT SHARED.txt'
        mount --bind #{src} #{dest}
      ",
      run: 'always'
  end

  # If you need to remove an old bind, you can run these commands:
  # sudo umount /vagrant/node_modules
  # sudo rm -rf /vagrant/node_modules
  # sudo rm -rf /srv/node_modules

  #===============================================================================
  # VirtualBox config
  #===============================================================================

  config.vm.provider 'virtualbox' do |vb|

    # RAM
    vb.memory = memory_size

    # Virtual CPUs
    vb.cpus = cpu_count

    # Limit the percent of the host processor that can be used
    vb.customize ['modifyvm', :id, '--cpuexecutioncap', cpu_cap]

    # Display the VirtualBox GUI when booting the machine - for debugging:
    # $ GUI=1 vagrant up
    vb.gui = (ENV['GUI'] == '1')

    # Upgrade VirtualBox Guest Additions automatically - I ran into problems
    # when it was out of date, and it's generally a good idea for the guest to
    # have the same version as the host
    if not Vagrant.has_plugin?('vagrant-vbguest')
      # There are no settings here, we just check that the plugin is installed
      puts '** Warning: vagrant-vbguest plugin is not installed - suggest you run:'
      puts '   vagrant plugin install vagrant-vbguest'
      puts
    end

  end

  #===============================================================================
  # Provisioning
  #===============================================================================

  # Cache packages for faster provisioning
  if Vagrant.has_plugin?('vagrant-cachier')

    # Share the cache between projects, since we only have a single VM
    # http://fgrehm.viewdocs.io/vagrant-cachier/usage#user-content-cache-scope
    config.cache.scope = :box

    # Manual configuration reduces provisioning time
    # See "Available buckets" at http://fgrehm.viewdocs.io/vagrant-cachier
    config.cache.auto_detect = false
    config.cache.enable :apt
    config.cache.enable :gem

  else
    puts '** Warning: Cachier plugin is not installed - suggest you run:'
    puts '   vagrant plugin install vagrant-cachier'
    puts
  end

  # Ansible Provisioner - runs Ansible directly on the VM because the built-in
  # provisioner doesn't work on Windows. Note: We could check to see if Ansible
  # is installed on the host machine (if it's Mac/Linux), but we don't use any
  # other OS's and I don't want to complicate things. If someone wants to add
  # this in the future, I recommend looking at Phansible.
  # https://github.com/phansible/phansible/blob/abd48a06aaea58063c754c6e6ec7255c3ea829e5/Vagrantfile#L25
  config.vm.provision 'ansible',
    type:       :shell,
    path:       'scripts/ansible.sh',
    args:       ENV['DEBUG'] ? '-vvv' : '', # Use "DEBUG=1 vagrant provision" to enable debugging
    privileged: false,
    keep_color: true

  #===============================================================================
  # Git filemodes
  #===============================================================================

  # Cygwin Git supports filemodes (executable bit, +x), but VirtualBox's shared
  # folders don't (nor do many Windows applications), so we have to disable them
  if Vagrant::Util::Platform.cygwin?
    if Vagrant.has_plugin?('vagrant-triggers')

      config.trigger.before :up do
        if not File.exists?(__dir__ + '/.git')
          run 'git init'
        end
        run 'git config core.filemode false'
      end

    else
      puts '** Warning: Triggers plugin is not installed - suggest you run:'
      puts '   vagrant plugin install vagrant-triggers'
      puts
    end
  end

  #===============================================================================
  # SSH settings
  #===============================================================================

  # Enable SSH agent forwarding
  config.ssh.forward_agent = true

  #===============================================================================
  # Custom settings
  #===============================================================================
  # Add any other project-specific configuration here...



end

#===============================================================================
# Initial Setup
#===============================================================================

$doing_setup = false

def start_setup
  unless $doing_setup
    puts
    puts "\e[32;1m*** Setup **********************************************************************\e[0m"
    puts
    $doing_setup = true
  end
end

def check_setup(hostname)

  #---------------------------------------
  # Project title
  #---------------------------------------

  if File.exists?(__dir__ + '/CHANGEME.sublime-project')
    start_setup

    print "\e[33;1mProject Name\e[0m (e.g. My Project): \e[37;1m"
    project_name = $stdin.gets.chomp
    if project_name != ''
      File.rename(__dir__ + '/CHANGEME.sublime-project', __dir__ + '/' + project_name + '.sublime-project')
    end
  end

  #---------------------------------------
  # Hostname
  #---------------------------------------

  default_hostname = 'CHANGE' + 'ME.test'

  if hostname == default_hostname
    start_setup

    # Ask for a new hostname
    print "\e[33;1mHostname\e[0m (e.g. myproject.test): \e[37;1m"
    hostname.replace $stdin.gets.chomp
    exit! if hostname == ''

    # Update files
    [
      __dir__ + '/Vagrantfile',
      __dir__ + '/scripts/download-live-site.sh',
    ]
    .each do |filename|
      content = File.read(filename)
      content = content.gsub(default_hostname, hostname)
      File.open(filename, 'w') { |file| file.puts content }
    end

  end

  #---------------------------------------

  if $doing_setup
    puts
    puts "\e[32;1m********************************************************************************\e[0m"
    puts
  end

end

# -*- mode: ruby -*-
# vi: set ft=ruby :
