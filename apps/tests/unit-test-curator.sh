#!/bin/bash
set -e

script_name=$(basename $0 .sh)
echo "# $script_name inside curator container start"

ret=0
# detect TTY
if test -t 1 ; then
  DOCKER_USE_TTY="-t"
else
  DC_USE_TTY="-T"
fi

set +e
# elasticsearch status
test_status=OK
elasticsearch_url="http://${ES_HOST}:9200/_cluster/health"
test_name='elasticsearch $elasticsearch_url == green'
echo "# $script_name: $test_name"
timeout=120
test_result=1
until [ "$timeout" -le 0 -o "$test_result" -eq "0" ] ; do
  test_output=$( curl -s -XGET --retry 1 --retry-delay 1  --retry-max-time 120 "$elasticsearch_url")
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

# test curator config syntax
test_status=OK
service_name="curator"
test_name='crontab -l && config syntax /config/config_file.yml /config/action_file.yml'
echo "# $script_name: $test_name"
test_output=$( crontab -l && /usr/local/bin/curator --config /config/config_file.yml /config/action_file.yml --dry-run )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	echo "ERROR: $test_output"
	ret=$test_result
	test_status=FAILED
fi
echo "# $script_name: $test_name $test_status"


set -e
exit $ret
