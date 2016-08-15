#!/bin/bash
set -o nounset -o pipefail
cd "$(dirname "$0")/.."

################################################################################
# On guest VM:
# Download the database and files from the live site.
#
# **Note:** You will need to have uploaded your SSH key to the live site in
# advance. If running on Jericho, you will need to know the root (sudo) password
# too.
################################################################################

# Based on:
# https://gist.github.com/davejamesmiller/3736585

#===============================================================================
# Settings
#===============================================================================


host=$(hostname -f)

if [ "$host" = "passwordgen.test" ]; then

    # Vagrant
    dev_url='passwordgen.test'
    dev_db_name='site'
    dev_db_user='vagrant'
    dev_db_pass='vagrant'

    chown=''

elif [ "$host" = "jericho.alberon.co.uk" -a "$PWD" = "/home/www/TODO.jericho.alberon.co.uk/repo" ]; then

    # Development site
    echo 'Site not configured. Please edit download-live-site.sh.' >&2; exit 1 # Remove this line
    dev_url='TODO.jericho.alberon.co.uk'
    dev_db_name='TODO'
    dev_db_user='TODO'
    dev_db_pass='TODO'

    chown="$USER:www"

elif [ "$host" = "baritone.alberon.co.uk" -a "$PWD" = "/home/TODO/vhosts/TODO.baritone.alberon.co.uk" ]; then

    # Staging site
    echo 'Site not configured. Please edit download-live-site.sh.' >&2; exit 1 # Remove this line
    dev_url='TODO.baritone.alberon.co.uk'
    dev_db_name='TODO'
    dev_db_user='TODO'
    dev_db_pass='TODO'

    chown=''

else
    echo "Unknown server ($host:$PWD)" >&2
    exit 1
fi

dev_files_path='path/to/uploads' # Absolute or relative to the current directory

# Directory to backup the development database to
backups_dir='backups/download-live-site'

# Live site
live_url='www.example.com'
live_ssh_host='baritone.alberon.co.uk'
live_ssh_user=''
live_db_name=''
live_db_user=''
live_db_pass=''
live_files_path='repo/path/to/uploads' # Absolute or relative to $HOME (if using SSH) or current directory (if local)

# List of tables to skip the content, e.g. large log tables
# e.g. 'rbls_redirection_404 rbls_redirection_logs'
db_structure_only=''

# MySQL script to run after downloading the development database
read -r -d '' mysql_script <<END_MYSQL_SCRIPT
END_MYSQL_SCRIPT

# PHP script to run after downloading the development database
# (Useful for altering serialized data, which is tricky/impossible to do through SQL)
read -r -d '' php_script <<'END_PHP_SCRIPT'
END_PHP_SCRIPT

# Other commands to run
update_db()
{
    : # Do nothing
}

#===============================================================================

# Check the settings have been filled in above
if [ -z "$live_db_name" ]; then
    echo "This script has not been configured correctly." >&2
    exit 1
fi

# Make sure this isn't run accidentally
source "$(dirname "$0")/_includes/ask.sh"
ask 'Are you sure you want to overwrite the development site?' || exit

# Take ownership of files, to ensure they are overwritten properly later
if [ -n "$dev_files_path" -a -n "$chown" ]; then
    echo "Taking ownership of files in $dev_files_path..."
    sudo chown -R "$chown" "$dev_files_path" || exit
fi

# Backup database
if [ -n "$backups_dir" ]; then
    echo "Backing up existing development database..."
    if [ ! -d "$backups_dir" ]; then
        mkdir -p "$backups_dir" || exit
    fi
    mysqldump --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$dev_db_user" "$dev_db_pass") --skip-lock-tables "$dev_db_name" | bzip2 -9 > "$backups_dir/$(date +%Y-%m-%d-%H.%M.%S).sql.bz2" || exit
fi

# Empty database
echo "Clearing existing development database..."
tables=$(mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$dev_db_user" "$dev_db_pass") "$dev_db_name" -Ne "SHOW TABLES")

(
    echo "SET FOREIGN_KEY_CHECKS = 0;"
    while read -r table; do
        if [ -n "$table" ]; then
            echo "DROP TABLE \`$table\`;"
        fi
    done <<< "$tables"
    echo "SET FOREIGN_KEY_CHECKS = 1;"
    echo "ALTER DATABASE DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
) | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$dev_db_user" "$dev_db_pass") "$dev_db_name" || exit

# Copy database
echo "Copying database..."

ignore_tables=''
for table in $db_structure_only; do
    ignore_tables="$ignore_tables --ignore-table=\"$live_db_name.$table\""
done

if [ -n "$live_ssh_host" ]; then

    # Via SSH

    # Structure & data
    printf "[client]\nuser = %s\npassword = %s" "$live_db_user" "$live_db_pass" \
        | ssh "$live_ssh_user@$live_ssh_host" "mysqldump --defaults-extra-file=<(cat) --skip-lock-tables '$live_db_name' $ignore_tables | nice bzip2 -9" \
        | bunzip2 \
        | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$dev_db_user" "$dev_db_pass") "$dev_db_name" \
        || exit

    # Structure only
    if [ -n "$db_structure_only" ]; then
        printf "[client]\nuser = %s\npassword = %s" "$live_db_user" "$live_db_pass" \
            | ssh "$live_ssh_user@$live_ssh_host" "mysqldump --defaults-extra-file=<(cat) --skip-lock-tables '$live_db_name' --no-data $db_structure_only | nice bzip2 -9" \
            | bunzip2 \
            | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$dev_db_user" "$dev_db_pass") "$dev_db_name" \
            || exit
    fi

else

    # Local

    # Structure & data
    mysqldump --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$live_db_user" "$live_db_pass") --skip-lock-tables "$live_db_name" $ignore_tables \
        | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$dev_db_user" "$dev_db_pass") "$dev_db_name" \
        || exit

    # Structure only
    if [ -n "$db_structure_only" ]; then
        mysqldump --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$live_db_user" "$live_db_pass") --skip-lock-tables "$live_db_name" --no-data $db_structure_only \
            | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$dev_db_user" "$dev_db_pass") "$dev_db_name" \
            || exit
    fi

fi

# Update database
if [ -n "$mysql_script" -o -n "$php_script" ]; then
    echo "Updating database..."
fi

if [ -n "$mysql_script" ]; then
    echo "$mysql_script" | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$dev_db_user" "$dev_db_pass") "$dev_db_name" || exit
fi

if [ -n "$php_script" ]; then
    echo "<?php $php_script" | php || exit
fi

update_db

# Copy files
if [ -n "$dev_files_path" -a -n "$live_files_path" ]; then
    echo "Copying files to $dev_files_path..."
    rsync="nice rsync" # Use less CPU & IO to avoid overloading the servers
    if [ -n "$live_ssh_host" ]; then
        $rsync -r --links --delete --stats --progress --compress --rsync-path="$rsync" "$live_ssh_user@$live_ssh_host:$live_files_path/" "$dev_files_path" || exit
    else
        $rsync -r --links --delete --stats --progress "$live_files_path/" "$dev_files_path" || exit
    fi
    echo
    chmod ug+rwX -R "$dev_files_path" || exit
fi

# Done
echo "Done."
