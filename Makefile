# Makefile — Dockerised validation for this Ansible repo

SHELL := /bin/bash

# --- Core docker run params ---------------------------------------------------
DOCKER      ?= docker
REPO_ROOT   := $(shell pwd)
UID_GID     := $(shell id -u):$(shell id -g)
MOUNT       := -v $(REPO_ROOT):/workspace -w /workspace
NET         ?= --network=host

ifeq ($(CI),true)
TTY :=
else
TTY := -t
endif

RUN := $(DOCKER) run --rm $(TTY) -u $(UID_GID) $(NET) $(MOUNT)

# Official Ansible Dev Tools image (bundles ansible-lint AND yamllint)
ANSIBLE_DEV_TOOLS_IMG ?= ghcr.io/ansible/community-ansible-dev-tools:v25.5.2

# Where Galaxy collections are installed (and cached in CI)
GALAXY_DIR ?= .ansible/collections

.PHONY: help validate validate-ansible validate-yaml galaxy-install

help:
	@echo "Targets:"
	@echo "  make validate           - run YAML + Ansible validation via Docker"
	@echo "  make validate-yaml      - run yamllint via Docker"
	@echo "  make validate-ansible   - run ansible-lint via Docker"
	@echo "  make galaxy-install     - install Galaxy collections into $(GALAXY_DIR) via Docker"

validate: validate-yaml validate-ansible

validate-yaml:
	@$(RUN) $(ANSIBLE_DEV_TOOLS_IMG) bash -lc 'FILES="$$(git ls-files \"*.yml\" \"*.yaml\")"; \
	 if [ -n "$$FILES" ]; then yamllint -f github $$FILES; else echo "No YAML files to lint"; fi'

validate-ansible:
	@$(RUN) $(ANSIBLE_DEV_TOOLS_IMG) bash -lc "ansible-lint -v"

galaxy-install:
	@mkdir -p $(GALAXY_DIR)
	@$(RUN) $(ANSIBLE_DEV_TOOLS_IMG) \
		bash -lc 'if [[ -f requirements.yml ]]; then ansible-galaxy collection install -r requirements.yml -p "$(GALAXY_DIR)"; else echo "requirements.yml not found"; fi'
