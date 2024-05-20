SHELL=/bin/bash
DOCKER=/usr/bin/docker
DOCKER_IMAGE_NAME=edgd1er/rpi-icinga-nconf
PTF=linux/amd64
DKRFILE=./Dockerfile.all
DKRFILEDOC=./Dockerfile.builddoc
ARCHI := $(shell dpkg --print-architecture)
IMAGE=rpi-icinga-nconf
IMAGEDOC=icinga-doc
DUSER=edgd1er
PROGRESS=auto
WHERE=--load
CACHE=
aptCacher:=$(shell ifconfig wlp2s0 | awk '/inet /{print $$2}')

default: build
all: lint build test

# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# Fichiers/,/^# Base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

lint:
	$(DOCKER) run --rm -i hadolint/hadolint < Dockerfile.builddoc
	$(DOCKER) run --rm -i hadolint/hadolint < Dockerfile.all

doc:
ifneq ($(shell docker container ls -a|grep -c tmp_doc),0)
	${DOCKER} container rm tmp_doc
endif
	$(DOCKER) build $(WHERE) -f $(DKRFILEDOC) -t ${IMAGEDOC} .
	${DOCKER} create --rm --name tmp_doc ${IMAGEDOC}
	${DOCKER} cp tmp_doc:/var/www/html/doc.tar.gz .


build:
	$(DOCKER) buildx build $(WHERE) --platform $(PTF) -f $(DKRFILE) $(CACHE) --progress $(PROGRESS) \
 	--build-arg aptCacher=$(aptCacher) -t ${DUSER}/$(IMAGE) .

push:
	$(DOCKER) login
	$(DOCKER) push $(DOCKER_IMAGE_NAME)

test:
	$(DOCKER) run --rm $(DOCKER_IMAGE_NAME) --version

clean:
	$(DOCKER) images -qf dangling=true | xargs --no-run-if-empty $(DOCKER) rmi
	$(DOCKER) volume ls -qf dangling=true | xargs --no-run-if-empty $(DOCKER) volume rm
