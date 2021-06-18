#!/bin/bash
# set -x
echo "## connection test"

host_ip=localhost
kibana=http://$host_ip/kibana/api/status
curl_args="--connect-timeout 1 --retry 1 --retry-delay 1 --retry-max-time 1 --max-time 1"
set +e
RETRY_NB=240
RETRY_DELAY_IN_SEC=1
n=0
test_result=1
echo "# Wait $RETRY_NB second for $kibana"
until [ $n -ge $RETRY_NB ] || [ $test_result -eq 0 ]
do
        if ( curl --silent --fail -s $curl_args $kibana || echo '{}' )|jq -re '.status.overall.state' | grep 'green' ; then
          echo "Test passed"
          test_result=0;
        else
          echo "Test failed at $n/$RETRY_NB try"
          sleep $RETRY_DELAY_IN_SEC
        fi
        ((n++))
done
ret=$test_result
set -e
exit $test_result
