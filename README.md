# postgres-ha

Ansible playbooks to stand up PostgreSQL streaming replication on three
Linux VMs, coordinated by a three-node ZooKeeper ensemble.

## Goal

- Three VMs, each running ZooKeeper (quorum) and PostgreSQL.
- Patroni uses ZooKeeper as its DCS and manages primary election.
- Streaming replication between the current primary and two replicas.
- Automatic failover when the primary is lost.

## Target stack (January 2022 releases)

Versions below were already published when this repo started.
Later commits bump pins as new upstream releases land.

| Component   | Version | Upstream release |
|-------------|---------|------------------|
| OS          | Ubuntu 20.04 LTS | 2020-04-23 |
| PostgreSQL  | 14.1    | 2021-11-11 |
| ZooKeeper   | 3.7.0   | 2021-03-27 |
| Patroni     | 2.1.2   | 2021-12-03 |
| Ansible     | 2.12    | 2021-11-08 |

Work in progress — roles and playbooks will land incrementally.
