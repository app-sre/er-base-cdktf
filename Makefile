IMAGE=quay.io/app-sre/er-base-cdktf:0.0.1

.PHONY: all
all: build push

.PHONY: build
build:
	docker build -t ${IMAGE} .

.PHONY: push
push:
	docker push ${IMAGE}
