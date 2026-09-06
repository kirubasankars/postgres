INVENTORY ?= inventories/ha/hosts.yml
PLAYBOOKS := playbooks/site.yml playbooks/zookeeper.yml playbooks/postgres.yml playbooks/healthcheck.yml
ANSIBLE_PLAYBOOK ?= ansible-playbook
COMPOSE ?= docker compose -f docker/compose.yaml
# Extra flags for any target, e.g. make healthcheck FLAGS="--limit pg-zk-01"
FLAGS ?=

RUN = $(ANSIBLE_PLAYBOOK) -i $(INVENTORY)

.DEFAULT_GOAL := help
.PHONY: help deps syntax lint deploy zookeeper postgres healthcheck status \
	lab lab-destroy lab-docker lab-docker-destroy

help:
	@echo "Targets:"
	@echo "  deps                install required Ansible collections"
	@echo "  syntax              syntax-check every playbook"
	@echo "  lint                run ansible-lint if it is installed"
	@echo "  deploy              ZooKeeper ensemble, then PostgreSQL/Patroni"
	@echo "  zookeeper           ensemble only"
	@echo "  postgres            PostgreSQL/Patroni only (needs quorum)"
	@echo "  healthcheck         assert ZooKeeper quorum and one Patroni primary"
	@echo "  status              print raw ZooKeeper and Patroni state"
	@echo "  lab                 three local VMs via Vagrant"
	@echo "  lab-destroy         tear the local VMs down"
	@echo "  lab-docker          three Fedora containers via docker compose"
	@echo "  lab-docker-destroy  tear the containers down"
	@echo
	@echo "Variables: INVENTORY=$(INVENTORY) FLAGS="
	@echo "Against the container lab, add INVENTORY=inventories/docker/hosts.yml"

deps:
	ansible-galaxy collection install -r requirements.yml

syntax:
	$(RUN) --syntax-check $(PLAYBOOKS)

lint:
	@command -v ansible-lint >/dev/null 2>&1 \
		&& ansible-lint $(PLAYBOOKS) roles \
		|| echo "ansible-lint not installed, skipping"

deploy:
	$(RUN) playbooks/site.yml $(FLAGS)

zookeeper:
	$(RUN) playbooks/zookeeper.yml $(FLAGS)

postgres:
	$(RUN) playbooks/postgres.yml $(FLAGS)

# Fails when ZooKeeper has no quorum or the cluster has no single primary.
healthcheck:
	$(RUN) playbooks/healthcheck.yml $(FLAGS)

status:
	scripts/cluster-status.sh $(INVENTORY)

lab:
	vagrant up

lab-destroy:
	vagrant destroy -f

# --wait holds until systemd has booted in all three containers.
lab-docker:
	$(COMPOSE) up -d --build --wait
	@echo "Now: make deploy INVENTORY=inventories/docker/hosts.yml"

lab-docker-destroy:
	$(COMPOSE) down -v
