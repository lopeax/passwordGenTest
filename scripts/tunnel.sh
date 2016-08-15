#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/.."

################################################################################
# On guest VM:
# Start a tunnel to ngrok (https://ngrok.com/) to allow testing with external
# services such as BrowserStack (https://www.browserstack.com/), or APIs such
# as PayPal IPN (http://bit.ly/1MEPPtj).
#
# **Note:** Only works with non-SSL traffic (port 80) - a paid account is
# required to test SSL sites.
################################################################################

ngrok http 80
