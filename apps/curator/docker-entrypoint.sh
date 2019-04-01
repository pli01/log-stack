#!/bin/bash
#
# configuration curator
#
set -e

cat > /tmp/crontab.run <<EOF
# configuration
UNIT=${UNIT:-months}
UNIT_COUNT=${UNIT_COUNT:-1}
DISK_SPACE=${DISK_SPACE:-20}
ES_HOST=${ES_HOST:-127.0.0.1}
USE_SSL=${USE_SSL:-False}
HTTP_AUTH=${HTTP_AUTH:-''}
TIMEOUT=${TIMEOUT:-120}
MASTER_ONLY=${MASTER_ONLY:-True}
#
EOF
cat /config/crontab.txt >> /tmp/crontab.run

[ -f /tmp/crontab.run ] && /usr/bin/crontab /tmp/crontab.run

/usr/sbin/cron -f -L 15
