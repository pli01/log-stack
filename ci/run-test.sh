#!/bin/bash
set -e
echo "# build"
make build
echo "# run test"
make -f Makefile.test efk-clean-test && make -f Makefile.test unit-test
docker images && docker ps
echo "# clean"
make -f Makefile.test efk-clean-test || true
