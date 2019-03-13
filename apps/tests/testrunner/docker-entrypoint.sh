#!/bin/bash
#
# entrypoint testrunner curator
#
set -e

# config.cfg
cat > /config/config.cfg <<EOF
# configuration
TIMEOUT=${TIMEOUT:-120}
#
EOF
cat /config/config.cfg
source /config/config.cfg

# sleep
while :; do echo 'Hit CTRL+C'; sleep 1; done

