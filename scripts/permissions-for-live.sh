#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/.."

################################################################################
# On live server:
# Set file permissions so other users cannot read sensitive files.
################################################################################

# Make sure files are writable by the user but not others
chmod u+rwX,go+rX-w -R . &&

# These directories don't need to be readable by Apache or other users
#chmod go-rwx -R sessions &&

# PHP files don't need to be readable by Apache or other users
find . -name '*.php' -exec chmod go-rwx '{}' +
