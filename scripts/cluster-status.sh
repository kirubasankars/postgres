#!/bin/sh
# Print ZooKeeper ruok/srvr and Patroni cluster JSON from the inventory.
# Usage: scripts/cluster-status.sh [inventory]
set -eu

INVENTORY="${1:-inventories/ha/hosts.yml}"

echo "== ZooKeeper =="
ansible zookeeper -i "$INVENTORY" -b -m shell \
  -a 'echo ruok | nc -w 3 127.0.0.1 2181; echo; echo srvr | nc -w 3 127.0.0.1 2181 | grep Mode'

echo "== Patroni =="
ansible postgres -i "$INVENTORY" -b -m uri \
  -a 'url=http://127.0.0.1:8008/cluster return_content=true'
