#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/.."

################################################################################
# On guest VM:
# Export all databases from the MySQL server to corresponding files in the
# `database/` directory. This allows you to commit them to the Git repo for
# other developers to use.
#
# **Note:** Uploaded files are not (and should not be) committed to the repo. If
# they are needed, consider using `download-live-site.sh` to set up the
# development environment instead.
################################################################################

# Which directory are we saving to?
dir="database"

if [ "${1:-}" = "--cron" ]; then
    dir="backups/cron"
fi

# Make sure the directory exists
mkdir -p "$dir" 2>/dev/null || true

# Save databases
save_db()
{
    # Don't print server information as it may cause unnecessary differences in Git
    mysqldump --skip-comments "$1" > "$dir/$1.sql"
}

save_db site
