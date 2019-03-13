#!/bin/bash
set -ex

script_name=$(basename $0 .sh)

echo "# $script_name start"
ret=0
if test -t 1 ; then
  DOCKER_USE_TTY="-t"
else
  DC_USE_TTY="-T"
fi

# test compose config
test_name="${EFK_DOCKER_COMPOSE_RUN} config"
echo "# $script_name: $test_name"
test_output=$( ( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} config 2>&1 ) )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	echo "ERROR: $test_output"
	ret=$test_result
	exit $ret
fi

# tar config
[ -z "$efk_stack_conf_dir" ] && exit 1
( cd ${TEST_APP_PATH} 
  conf_dir=$(basename ${efk_stack_conf_dir} )
  tar -zcvf ${TEST_APP_PATH}/config.tar.gz ${conf_dir} prepare-test.sh unit-test.sh
)

# start testrunner
( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} up --no-recreate --no-build -d --no-deps testrunner  )
testrunner_id=$( ( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} ps -q testrunner ) )

# copy config.tar in testrunner:/opt
docker cp ${TEST_APP_PATH}/config.tar.gz $testrunner_id:/opt/

# extract tar
( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} exec ${DC_USE_TTY} testrunner  /bin/bash -c '( cd /opt && sudo tar -zxvf config.tar.gz  && sudo chown debian. -R /opt )' )

# on testrunner: prepare config
test_name="run prepare-test.sh in testrunner"
echo "# $script_name: $test_name"
( cd ${APP_PATH} && ${DC} -f ${EFK_DOCKER_COMPOSE_RUN} exec ${DC_USE_TTY} testrunner  /bin/bash -c '( cd /opt && sudo chmod +x prepare-test.sh && ./prepare-test.sh )' )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	ret=$test_result
	exit $ret
fi

echo "# $script_name end"
exit $ret
