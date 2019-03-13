#!/bin/bash
set -e

script_name=$(basename $0 .sh)
echo "# $script_name inside testrunner container start"

ret=0
# detect TTY
if test -t 1 ; then
  DOCKER_USE_TTY="-t"
else
  DC_USE_TTY="-T"
fi

set +e
# test fluentd output local config
test_status=OK
test_name='fluentd conf/output/01-es.conf: /fluentd/log/app/${tag}/%Y%m%d%H/log.${tag}.%Y%m%d%H'
echo "# $script_name: $test_name"
timeout=120;
test_result=1
until [ "$timeout" -le 0 -o "$test_result" -eq "0" ] ; do
  test_output=$( ( find /fluentd/log |grep '/fluentd/log/app/${tag}/%Y%m%d%H/log.${tag}.%Y%m%d%H' ) )
  test_result=$?
  echo "Wait $timeout seconds: fluentd up $test_result";
  (( timeout-- ))
  sleep 1
done
echo "$test_output"
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	ret=$test_result
	test_status=FAILED
	exit $ret
fi
echo "# $script_name: $test_name $test_status"

# kibana status
test_status=OK
nginx_url="http://nginx/api/status"
test_name="kibana: $nginx_url == green"
echo "# $script_name: $test_name"
timeout=120;
test_result=1
until [ "$timeout" -le 0 -o "$test_result" -eq "0" ] ; do
  test_output=$( ( curl  --fail -sL "$nginx_url" || echo '{}' ) | jq -er 'if .status.overall.state then .status.overall.state=="green" else false end' )
  test_result=$?
  echo "Wait $timeout seconds: "$nginx_url" up $test_result";
  (( timeout-- ))
  sleep 1
done
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	ret=$test_result
	test_status=FAILED
	exit $ret
fi
echo "$nginx_url $test_output"
echo "# $script_name: $test_name $test_status"
#
# elasticsearch status
test_status=OK
elasticsearch_url="http://elasticsearch:9200/_cluster/health"
test_name='elasticsearch $elasticsearch_url == green'
echo "# $script_name: $test_name"
timeout=120
test_result=1
until [ "$timeout" -le 0 -o "$test_result" -eq "0" ] ; do
  test_output=$( ( curl -s --fail -XGET "$elasticsearch_url" || echo '{}' ) | jq -e 'if .status then .status!="red" else false end' )
  test_result=$?
  echo "Wait $timeout seconds: "$elasticsearch_url" up $test_result";
  (( timeout-- ))
  sleep 1
done
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	ret=$test_result
	test_status=FAILED
	exit $ret
fi
echo "$elasticsearch_url $test_output"
echo "# $script_name: $test_name $test_status"

set -e
exit $ret
