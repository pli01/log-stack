##############################################
# WARNING : THIS FILE SHOULDN'T BE TOUCHED   #
#    FOR ENVIRONNEMENT CONFIGURATION         #
# CONFIGURABLE VARIABLES SHOULD BE OVERRIDED #
# IN THE 'artifacts' FILE, AS NOT COMMITTED  #
##############################################

#export PORT=80
export APP ?= log-stack
export SHELL=/bin/bash
export ROOT_DIR= $(shell pwd)
export APP_PATH := $(shell cd apps && pwd)
export APP_DATA ?= $(APP_PATH)/data
export APP_VERSION ?= $(shell bash ./ci/version.sh 2>&- || cat VERSION)
export DC_DIR=${APP_PATH}
export DC_PREFIX=${DC_DIR}/docker-compose
export BUILD_DIR=${ROOT_DIR}/${APP}-${APP_VERSION}-build

export NPM_REGISTRY ?= $(shell echo $$NPM_REGISTRY )
export SASS_REGISTRY ?= $(shell echo $$SASS_REGISTRY )
export dml_url = $(shell echo $$dml_url )
export openstack_token = $(shell echo $$openstack_token )
export publish_dir ?= $(APP)

export dollar = $(shell echo \$$)
export curl_args = $(shell echo $$curl_args)
# detect tty
export DOCKER_USE_TTY := $(shell test -t 1 && echo "-t" )
export DC_USE_TTY     := $(shell test -t 1 || echo "-T" )

#
# cli docker-compose
export DC_BUILD_ARGS := --pull --no-cache --force-rm
export DC_RUN_ARGS   := -d --no-build

# elastic conf
export ES_MEM ?= 2048m
export ES_HOST ?= elasticsearch
export KIBANA_ACCESS_LIST ?= ["all"]
# fluentd conf
export UNIT_COUNT ?= 10
export DISK_SPACE ?= 10

vm_max_count		:= $(shell cat /etc/sysctl.conf | egrep vm.max_map_count\s*=\s*262144 && echo true)

dummy               := $(shell touch artifacts)
DC := docker-compose

SHELL:=/bin/bash

# override default values
include ./artifacts

# include app default values
include apps/Makefile.efk


install-prerequisites:
ifeq ("$(wildcard /usr/bin/docker)","")
	echo install docker-ce, still to be tested
	sudo apt-get update
	sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common

        curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo apt-key add -
        sudo add-apt-repository \
                "deb https://download.docker.com/linux/`lsb_release -is | awk ' { print tolower($$1)} '` \
                `lsb_release -cs` \
                stable"
	sudo apt-get update
	sudo apt-get install -y docker-ce
	@(if (id -Gn ${USER} | grep -vc docker); then sudo usermod -aG docker ${USER} ;fi) > /dev/null
endif
ifeq ("$(wildcard /usr/bin/gawk)","")
	@echo installing gawk
	@sudo apt-get install -y gawk
endif
ifeq ("$(wildcard /usr/bin/jq)","")
	@echo installing jq
	@sudo apt-get install -y jq
endif
ifeq ("$(wildcard /usr/local/bin/docker-compose)","")
	@echo installing docker-compose
	@sudo curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	@sudo chmod +x /usr/local/bin/docker-compose
endif

vm_max:
ifeq ("$(vm_max_count)", "")
	@echo updating vm.max_map_count $(vm_max_count) to 262144
	sudo sysctl -w vm.max_map_count=262144
endif

build-dir:
	if [ ! -d "$(BUILD_DIR)" ] ; then mkdir -p $(BUILD_DIR) ; fi

build-dir-clean:
	if [ -d "$(BUILD_DIR)" ] ; then rm -rf $(BUILD_DIR) ; fi

build: build-dir build-archive efk-build

build-archive: clean-archive
	@echo "Build $(APP) $(APP)-$(APP_VERSION) archive"
	echo "$(APP_VERSION)" > VERSION ; cp VERSION $(BUILD_DIR)/$(APP)-VERSION
	tar -zcvf $(BUILD_DIR)/$(APP)-$(APP_VERSION)-archive.tar.gz --exclude $$(basename $(BUILD_DIR)) *
	@echo "Build $(APP) $(APP)-latest archive"
	cp $(BUILD_DIR)/$(APP)-$(APP_VERSION)-archive.tar.gz $(BUILD_DIR)/$(APP)-latest-archive.tar.gz

clean: build-dir-clean efk-clean

clean-archive:
	@echo "Clean $(APP) archive"
	rm -rf $(APP)-$(APP_VERSION)-archive.tar.gz

unit-test: efk-test

publish: efk-publish
	@echo "Publish $(APP) $(APP_VERSION) artifacts"
	if [ -z "$(dml_url)" -o -z "$(openstack_token)" ] ; then exit 1 ; fi
	( cd $(BUILD_DIR) ;\
	  ls -alrt ;\
	    for file in \
                $(APP)-VERSION \
                $(APP)-$(APP_VERSION)-archive.tar.gz \
           ; do \
            curl $(curl_args) -k -X PUT -T $$file -H 'X-Auth-Token: $(openstack_token)' $(dml_url)/$(publish_dir)/$(APP_VERSION)/$$file ; \
           done ; \
          curl $(curl_args) -k -H 'X-Auth-Token: $(openstack_token)' "$(dml_url)/$(publish_dir)?prefix=$(APP_VERSION)/&format=json" -s --fail | jq '.[] | [  .content_type, .hash, .last_modified , .name + ": " + (.bytes|tostring) ] | join(" ")' ; \
	    for file in \
                $(APP)-VERSION \
                $(APP)-latest-archive.tar.gz \
           ; do \
            curl $(curl_args) -k -X PUT -T $$file -H 'X-Auth-Token: $(openstack_token)' $(dml_url)/$(publish_dir)/latest/$$file ; \
           done ; \
          curl $(curl_args) -k -H 'X-Auth-Token: $(openstack_token)' "$(dml_url)/$(publish_dir)?prefix=latest/&format=json" -s --fail | jq '.[] | [  .content_type, .hash, .last_modified , .name + ": " + (.bytes|tostring) ] | join(" ")' ; \
	)
