DOCKER=/usr/bin/docker
DOCKER_IMAGE_NAME=edgd1er/rpi-icinga-nconf
PTF=linux/amd64
DKRFILE=./Dockerfile.all
ARCHI=$(dpkg --print-architecture)
IMAGE=rpi-icinga-nconf
PROGRESS=AUTO
WHERE=--load
CACHE=

aptCacher=

default: build

lint:
	$(DOCKER) run --rm -i hadolint/hadolint < Dockerfile.all

build:
	$(DOCKER) buildx build $(WHERE) --platform $(PTF) -f $(DKRFILE) --build-arg NAME=$(NAME) \
    $(CACHE) --progress $(PROGRESS) --build-arg aptCacher=$aptCacher -t $(IMAGE) .

push:
	$(DOCKER) login
	$(DOCKER) push $(DOCKER_IMAGE_NAME)

test:
	$(DOCKER) run --rm $(DOCKER_IMAGE_NAME) --version

clean:
	$(DOCKER) images -qf dangling=true | xargs --no-run-if-empty $(DOCKER) rmi
	$(DOCKER) volume ls -qf dangling=true | xargs --no-run-if-empty $(DOCKER) volume rm
