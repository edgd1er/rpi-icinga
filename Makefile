DOCKER=/usr/bin/docker
DOCKER_IMAGE_NAME=edgd1er/rpi-icinga-nconf:armhf
DOCKER_BASE_NAME=resin/rpi-raspbian
DOCKER_BASE_VERSION=stretch

default: build

build:
	$(DOCKER) pull $(DOCKER_BASE_NAME):$(DOCKER_BASE_VERSION) 
	$(DOCKER) build --no-cache -t $(DOCKER_IMAGE_NAME) .

push:
	$(DOCKER) login
	$(DOCKER) push $(DOCKER_IMAGE_NAME)

test:
	$(DOCKER) run --rm $(DOCKER_IMAGE_NAME) --version

clean:
	$(DOCKER) images -qf dangling=true | xargs --no-run-if-empty $(DOCKER) rmi
	$(DOCKER) volume ls -qf dangling=true | xargs --no-run-if-empty $(DOCKER) volume rm
