#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")"
umask 022

################################################################################
# On guest VM:
# Install and run Ansible (provisioner) on the Vagrant VM.
#
# Additional parameters are passed to ansible-playbook, e.g.
# `t ansible --start-at-task="Task Name"`
################################################################################

#===============================================================================
# Helpers
#===============================================================================

is_installed() {
    which "$1" &>/dev/null
}

#===============================================================================
# Debug (verbose) mode?
#===============================================================================

if [ "${1:-}" = "-vvv" ]; then
    q=
    qq=
    output=">&1"
    set -x
else
    q="-q"
    qq="-qq"
    output="/dev/null"
fi

#===============================================================================
# Install Ansible
#===============================================================================

if ! is_installed ansible-playbook; then

    if [ -f /etc/lsb-release ]; then

        # Ubuntu
        source /etc/lsb-release
        export DEBIAN_FRONTEND=noninteractive

        # Add repository
        echo "Adding ppa:ansible/ansible repository..."
        sudo apt-get install -qqy python-software-properties
        sudo add-apt-repository -y ppa:ansible/ansible > $output

        # http://askubuntu.com/a/197532
        sudo apt-get update $qq -y -o Dir::Etc::sourcelist="sources.list.d/ansible-ansible-$DISTRIB_CODENAME.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"

        # Install Ansible
        echo "Installing Ansible..."
        sudo apt-get install -y ansible > $output

    elif is_installed apt-get; then

        # Debian
        export DEBIAN_FRONTEND=noninteractive

        # Update Repositories
        echo "Updating APT sources..."
        sudo apt-get update $qq -y

        # Install pip
        echo "Installing pip..."
        sudo apt-get install -y python-pip python-dev > $output

        # Reinstall setuptools & pkg_resources because otherwise pip fails to run :-S
        echo "Reinstalling setuptools & pkg_resources..."
        sudo apt-get install -y --reinstall python-pkg-resources python-setuptools > $output
        sudo pip install $q --upgrade setuptools

        # Install Ansible
        echo "Installing Ansible..."
        sudo pip install $q --upgrade ansible

    elif is_installed yum; then

        # CentOS

        # Install EPEL - contains Ansible and pip
        echo "Installing EPEL..."
        sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
        sudo yum install $q -y epel-release

        # Install Ansible and pip
        echo "Installing Ansible and pip..."
        sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
        sudo yum install $q -y ansible python-pip

        # Upgrade Jinja2 (required to use the 'map' filter)
        echo "Upgrading Jinja2..."
        sudo pip install $q --upgrade jinja2

    fi

fi

#===============================================================================
# Install the hosts file
#===============================================================================

# Note: Copy not symlink the hosts file (or use it directly) because all shared
# files are marked as executable (at least on a Windows host)
sudo mkdir /etc/ansible 2>/dev/null || true
sudo cp -f /vagrant/ansible/hosts/vagrant /etc/ansible/hosts
sudo chmod 644 /etc/ansible/hosts

#===============================================================================
# Run Ansible
#===============================================================================

# Unbuffered to show line-by-line output (https://github.com/mitchellh/vagrant/pull/2275)
# Force colour because Ansible thinks there's no terminal
# Pass "-vvv" parameter to this script for verbose
# Set HOME=/root because "sudo provision.sh" doesn't work in Ubuntu otherwise
echo "Running Ansible..."
PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=True ansible-playbook "$@" /vagrant/ansible/playbook.yml
