#!/bin/bash
set -e
cd $(dirname $0) || exit 1
# Use nexus repo to speed up build if MIRROR_DEBIAN defined
echo "$http_proxy $no_proxy" && set -x && [ -z "$MIRROR_DEBIAN" ] || \
     sed -i.orig -e "s|http://deb.debian.org/debian|$MIRROR_DEBIAN/debian9|g ; s|http://security.debian.org/debian-security|$MIRROR_DEBIAN/debian9-security|g" /etc/apt/sources.list ; \
    apt-get -q update && \
    apt-get install -qy --no-install-recommends --force-yes \
    cron python-pip python-urllib3 python-yaml python-click curl python-setuptools python-wheel && \
    apt-get autoremove -y && apt-get autoclean -y &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# git needed if requirements contains git repo
set -ex && [ -z "$PYPI_URL" ] || pip_args=" --index-url $PYPI_URL " ; \
    [ -z "$PYPI_HOST" ] || pip_args="$pip_args --trusted-host $PYPI_HOST " ; \
    echo "$no_proxy" |tr ',' '\n' | sort -u |grep "^$PYPI_HOST$" || \
      [ -z "$http_proxy" ] || pip_args="$pip_args --proxy $http_proxy " ; \
    pip install $pip_args -I --no-deps -r /opt/requirements.txt

[ -f /config/crontab.txt ] && /usr/bin/crontab /config/crontab.txt

rm -rf /etc/crontab
