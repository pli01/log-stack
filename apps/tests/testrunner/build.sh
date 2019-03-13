#!/bin/bash
set -e
cd $(dirname $0) || exit 1

# Use nexus repo to speed up build if MIRROR_DEBIAN defined
echo "$http_proxy $no_proxy" && set -x && [ -z "$MIRROR_DEBIAN" ] || \
     sed -i.orig -e "s|http://deb.debian.org/debian|$MIRROR_DEBIAN/debian9|g ; s|http://security.debian.org/debian-security|$MIRROR_DEBIAN/debian9-security|g" /etc/apt/sources.list ; \
    apt-get -q update && \
    apt-get install -qy --no-install-recommends --force-yes \
      python-pip python-urllib3 python-yaml \
       sudo procps make apt-transport-https ca-certificates curl software-properties-common gawk jq parallel

# git needed if requirements contains git repo
if [ -f /opt/requirements.txt -a -s /opt/requirements.txt ]; then
set -ex && [ -z "$PYPI_URL" ] || pip_args=" --index-url $PYPI_URL " ; \
    [ -z "$PYPI_HOST" ] || pip_args="$pip_args --trusted-host $PYPI_HOST " ; \
    echo "$no_proxy" |tr ',' '\n' | sort -u |grep "^$PYPI_HOST$" || \
      [ -z "$http_proxy" ] || pip_args="$pip_args --proxy $http_proxy " ; \
    pip install $pip_args -I --no-deps -r /opt/requirements.txt
fi

useradd -m debian
usermod -aG sudo debian
echo "debian ALL=NOPASSWD: ALL" >> /etc/sudoers.d/debian
chmod 440 /etc/sudoers.d/debian

# clean apt
apt-get autoremove -y && apt-get autoclean -y &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


