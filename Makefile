CONTAINER_ENGINE ?= $(shell which podman >/dev/null 2>&1 && echo podman || echo docker)

.PHONY: test
test:
	# test binaries are installed
	cdktf --version
	terraform --version

	# test python setup
	python -c 'import cdktf'
	python3 -c 'import cdktf'

	# test /tmp is empty
	[ -z "$(shell ls -A /tmp)" ]

	# test /tmp is writable
	touch /tmp/test && rm /tmp/test

.PHONY: build
build:
	$(CONTAINER_ENGINE) build -t er-base-cdktf:test .

.PHONY: dev-venv
dev-venv:
	uv venv && uv pip install -r requirements.txt
