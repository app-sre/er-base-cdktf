CONTAINER_ENGINE ?= $(shell which podman >/dev/null 2>&1 && echo podman || echo docker)
IMAGE=quay.io/app-sre/er-base-cdktf
TAG=$(shell cat VERSION)

.PHONY: all
all: build push

.PHONY: build
build:
	${CONTAINER_ENGINE} build -t ${IMAGE}:${TAG} .

.PHONY: push
push:
	${CONTAINER_ENGINE} push ${IMAGE}:${TAG}

.PHONY: test
test: build
	@echo "No tests yet. Proceed with caution!"

.PHONY: deploy
deploy: build push
