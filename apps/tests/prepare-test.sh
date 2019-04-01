#!/bin/bash
set -ex
script_name=$(basename $0 .sh)
echo "# $script_name inside testrunner container start"

cd /opt || exit 1
# extract config file
[ -f config.tar.gz ] || exit 1
mkdir config
sudo tar -zxvf config.tar.gz -C /opt/
sudo chown debian. -R /opt/

# prepare config file / services
# nginx
( cd /opt/efk-conf/nginx
  sudo cp efk_80.conf /etc/nginx/conf.d/default.conf
  sudo cp efk_blockips.conf /etc/nginx/conf.d/00-blockips.conf
  sudo cp efk_blockips.conf.template /etc/nginx/conf.d/00-blockips.conf.template
  sudo chown root. /etc/nginx/conf.d/default.conf
  sudo chown root. /etc/nginx/conf.d/00-blockips.conf
  sudo chown root. /etc/nginx/conf.d/00-blockips.conf.template
)
# fluentd
( cd /opt/efk-conf/fluentd/conf && tar cf - . ) | ( cd /fluentd/etc && sudo tar xvf - )
sudo chown debian. /fluentd/etc -R
#
find /fluentd/etc/ /etc/nginx/conf.d/ -ls

# metricbeat
( cd /opt/efk-conf/metricbeat && tar cf - . ) | ( cd /metricbeat && sudo tar xvf - )
sudo chown root. -R /metricbeat/
#
sync ; sync
echo "# $script_name inside testrunner container end"
exit
