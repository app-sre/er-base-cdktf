IMAGE=quay.io/app-sre/er-base-cdktf:0.1.0

.PHONY: all
all: build push

.PHONY: build
build:
	docker build -t ${IMAGE} .

.PHONY: push
push:
	docker push ${IMAGE}
