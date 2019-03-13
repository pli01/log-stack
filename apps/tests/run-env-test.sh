#!/bin/bash
set -e

script_name=$(basename $0 .sh)
echo "# $script_name start"

ret=0
# detect TTY
if test -t 1 ; then
  DOCKER_USE_TTY="-t"
else
  DC_USE_TTY="-T"
fi

set +e
# test fluentd config syntax
test_status=OK
service_name="fluentd"
test_name="${EFK_DOCKER_COMPOSE_RUN} ${service_name}: "'config syntax --dry-run'
echo "# $script_name: $test_name"
test_output=$( ( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} run --rm --no-deps ${DC_USE_TTY} ${service_name} /bin/bash -c "fluentd -c /fluentd/etc/fluent.conf -p /fluentd/plugins --dry-run" ) )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	echo "ERROR: $test_output"
	ret=$test_result
	test_status=FAILED
fi
echo "# $script_name: $test_name $test_status"

# start all service
test_status=OK
test_name="${EFK_DOCKER_COMPOSE_RUN} up"
echo "# $script_name: $test_name"
( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} up -d --no-recreate --no-deps --no-build 2>&1 )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	ret=$test_result
	test_status=FAILED
	exit $ret
fi
echo "# $script_name: $test_name $test_status"

# test nginx config syntax
test_status=OK
service_name="nginx"
test_name="${EFK_DOCKER_COMPOSE_RUN} ${service_name}: "'config syntax'
echo "# $script_name: $test_name"
test_output=$( ( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} exec ${DC_USE_TTY} ${service_name} /bin/bash -c "/usr/sbin/nginx -t" ) )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	echo "ERROR: $test_output"
	ret=$test_result
	test_status=FAILED
fi
echo "# $script_name: $test_name $test_status"


# run unit-test
test_status=OK
service_name="testrunner"
test_name="${EFK_DOCKER_COMPOSE_RUN} ${service_name}: unit-test.sh"
echo "# $script_name: $test_name"
( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} exec ${DC_USE_TTY} ${service_name}  /bin/bash -c '( cd /opt && sudo chmod +x unit-test.sh && ./unit-test.sh )' )
#( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} up -d --no-recreate --no-deps --no-build 2>&1 )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	ret=$test_result
	test_status=FAILED
	exit $ret
fi
echo "# $script_name: $test_name $test_status"

# test curator config syntax
test_status=OK
service_name="curator"
test_name="${EFK_DOCKER_COMPOSE_RUN} ${service_name}: unit-test-curator.sh"
echo "# $script_name: $test_name"
# prepare unit-test-curator
curator_id=$( ( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} ps -q curator ) )
# copy unit-test-curator.sh in testrunner:/opt
docker cp ${TEST_APP_PATH}/unit-test-curator.sh $curator_id:/opt/

test_output=$( ( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} exec ${DC_USE_TTY} ${service_name} /bin/bash -c '( cd /opt && chmod +x unit-test-curator.sh && bash -x ./unit-test-curator.sh )' ) )
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
