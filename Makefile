# Official Ansible Dev Tools image (bundles ansible-lint AND yamllint) - (pin versions for reproducibility)
ANSIBLE_DEV_TOOLS_IMG ?= ghcr.io/ansible/community-ansible-dev-tools:v25.5.2

# Where Galaxy collections are installed (keep in sync with ansible.cfg)
GALAXY_DIR            ?= .ansible/collections
ANSIBLE_REQUIREMENTS  ?= requirements.yml
INVENTORY ?= inventory/hosts.yml

# --- Core docker run params ---------------------------------------------------
DOCKER      ?= docker
REPO_ROOT   := $(shell pwd)
UID_GID     := $(shell id -u):$(shell id -g)
MOUNT       := -v $(REPO_ROOT):/workspace -w /workspace
NET         ?= --network=host

SHELL := /bin/bash

# --- TTY handling -------------------------------------------------------------
ifeq ($(CI),true)
TTY :=
else
TTY := -t
endif

# Single docker run template (ansible.cfg drives paths)
RUN := $(DOCKER) run --rm $(TTY) -u $(UID_GID) $(NET) $(MOUNT)

# SSH agent forwarding (preferred: avoids copying private keys)
SSH_KEYS ?= true
ifeq ($(SSH_KEYS),true)
RUN := $(RUN) -e HOME=/home/ansible -v $(HOME)/.ssh:/home/ansible/.ssh:ro
endif

.PHONY: all help clean install test lint \
        validate validate-ansible validate-yaml \
        collections-clean collections-install collections-reset \
        verify bootstrap

# --- “Standard” entry points --------------------------------------------------

all: validate               ## Default action: run full validation

help:
	@echo "Targets:"
	@echo "  make all                 - default, runs 'validate'"
	@echo "  make install             - install dependencies (Ansible Galaxy collections)"
	@echo "  make test                - run test/validation pipeline (alias for 'validate')"
	@echo "  make lint                - run linters (yamllint + ansible-lint)"
	@echo "  make clean               - remove local artefacts (collections)"
	@echo "  make validate            - install collections, then run YAML + Ansible validation"
	@echo "  make validate-yaml       - run yamllint"
	@echo "  make validate-ansible    - run ansible-lint"
	@echo "  make collections-clean   - remove $(GALAXY_DIR)"
	@echo "  make collections-install - install from $(ANSIBLE_REQUIREMENTS) into $(GALAXY_DIR)"
	@echo "  make collections-reset   - clean + install collections"

install: collections-install

test: validate

lint: validate-yaml validate-ansible

clean: collections-clean

# --- Validation ---------------------------------------------------------------

# Install collections before running validation so local + CI behave the same
validate: collections-install validate-yaml validate-ansible

validate-yaml:
	@$(RUN) $(ANSIBLE_DEV_TOOLS_IMG) bash -lc 'FILES="$$(git ls-files \"*.yml\" \"*.yaml\")"; \
	 if [ -n "$$FILES" ]; then yamllint -f github $$FILES; else echo "No YAML files to lint"; fi'

validate-ansible:
	@$(RUN) $(ANSIBLE_DEV_TOOLS_IMG) bash -lc "ansible-lint -v"

# --- Collections lifecycle ----------------------------------------------------

collections-clean:
	@echo ">> Removing $(GALAXY_DIR)"
	@rm -rf "$(GALAXY_DIR)"

collections-install:
	@mkdir -p "$(GALAXY_DIR)"
	@$(RUN) $(ANSIBLE_DEV_TOOLS_IMG) bash -lc '\
		if [[ -f "$(ANSIBLE_REQUIREMENTS)" ]]; then \
			echo ">> Installing Ansible collections from $(ANSIBLE_REQUIREMENTS) into $(GALAXY_DIR)"; \
			ansible-galaxy collection install -r "$(ANSIBLE_REQUIREMENTS)" -p "$(GALAXY_DIR)"; \
		else \
			echo ">> $(ANSIBLE_REQUIREMENTS) not found; skipping collections install"; \
		fi'

collections-reset: collections-clean collections-install
	@echo ">> Collections reset complete"

# --- Execute Boot Strapping ------------------------------------------------------------

# bootstrap will verify hosts first, then run full site.yml
bootstrap: collections-install
	@echo ">> Running ansible-playbook with inventory $(RUN)"
	@$(RUN) $(ANSIBLE_DEV_TOOLS_IMG) bash -lc '\
		ansible-playbook -i $(INVENTORY) $(if $(wildcard secrets.yml),-e @secrets.yml) site.yml'