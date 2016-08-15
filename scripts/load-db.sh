#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/.."

################################################################################
# On guest VM:
# Import all databases from the SQL files in `database/` to the MySQL server.
#
# **Warning:** This will overwrite any local changes.
################################################################################

#===============================================================================
# Make sure this isn't run accidentally
#===============================================================================

source "$(dirname "$0")/_includes/ask.sh"
[ "${1:-}" = "-f" ] || ask 'Are you sure you want to overwrite the development site?' || exit

#===============================================================================
# Restore databases
#===============================================================================

restore_db()
{
    # Check the file exists
    if [ ! -f "database/$1.sql" ]; then
        echo "Skipping $1 - database/$1.sql does not exist" >&2
        return
    fi

    # Empty database
    tables=$(mysql "$1" -Ne "SHOW TABLES")

    (
        echo "SET FOREIGN_KEY_CHECKS = 0;"
        while read -r table; do
            if [ -n "$table" ]; then
                echo "DROP TABLE \`$table\`;"
            fi
        done <<< "$tables"
        echo "SET FOREIGN_KEY_CHECKS = 1;"
        echo "ALTER DATABASE DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    ) | mysql "$1" || exit

    # Restore database
    mysql "$1" < "database/$1.sql"
}

restore_db site
