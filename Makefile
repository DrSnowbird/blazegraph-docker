SHELL := /bin/bash

VERSION := 1.0.0

DOCKER_REPO := openkbs

## -- To Check syntax:
#  cat -e -t -v Makefile

# The name of the executable (default is current directory name)
# DOCKER := json-server-docker
DOCKER := $(shell echo $${PWD\#\#*/})

NAME := $(DOCKER)

#VOLUME_MAP := "-v $${PWD}/json:/project-json -v $${PWD}/data:/data"
VOLUME_MAP := 

# { no, on-failure, unless-stopped, always }
RESTART_OPTION := no

SHA := $(shell git describe --match=NeVeRmAtCh --always --abbrev=40 --dirty=*)

.PHONY : clean

clean :
	echo $(NAME) $(DOCKER_REPO)/$(DOCKER):$(VERSION) 

build:
	docker build --build-arg CIRCLE_SHA1="$(SHA)" --build-arg version=$(VERSION) -t $(DOCKER_REPO)/$(DOCKER):$(VERSION) .

push: build
	docker push $(DOCKER_REPO)/$(DOCKER):$(VERSION)
	
pull:
    docker pull $(DOCKER_REPO)/$(DOCKER):$(VERSION)

up: build
	docker-compose up -d

down:
	docker-compose down

run:
	docker run --name=$(NAME) --restart=$(RESTART_OPTION) $(VOLUME_MAP) $(DOCKER_REPO)/$(DOCKER):$(VERSION)

stop: run
	docker stop --name=$(NAME)

rmi:
	docker rmi $$(docker images -f dangling=true -q)

exec: up
	docker-compose exec $(DOCKER) /bin/bash
