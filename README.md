# postgres-ha

Ansible playbooks that install a three-node PostgreSQL streaming
replication cluster on Linux VMs. Patroni elects the primary and
stores its lock in a three-node ZooKeeper ensemble on the same hosts.

## Layout

```
inventories/ha/     three-node inventory, group_vars, host_vars
playbooks/          site.yml, zookeeper.yml, postgres.yml, healthcheck.yml
roles/              common, java, zookeeper, postgresql, patroni
docs/               architecture and failover notes
scripts/            cluster-status.sh
```

Each VM (`pg-zk-01`, `pg-zk-02`, `pg-zk-03`) runs:

- ZooKeeper 3.8.0 on 2181 / 2888 / 3888
- Patroni 2.1.4 on 8008
- PostgreSQL 14.6 on 5432

## Versions (released at the time of this work)

Pins follow upstream dates. The playbooks never reference a build
that had not been published yet.

| Component   | Pin    | Released   | Why this line                         |
|-------------|--------|------------|---------------------------------------|
| Ubuntu      | 20.04  | 2020-04-23 | Common 2022 LTS guest                 |
| ZooKeeper   | 3.8.0  | 2022-03-07 | Current 3.8; 3.8.1 is 2023-01-25      |
| PostgreSQL  | 14.6   | 2022-11-10 | Latest 14 minor in 2022; 15.0 skipped |
| Patroni     | 2.1.4  | 2022-06-01 | Last 2.1.x of 2022                    |
| kazoo       | 2.8.0  | 2019-01-15 | Patroni ZooKeeper DCS client          |
| OpenJDK     | 11     | LTS        | Required by ZooKeeper 3.8             |
| Ansible     | 2.12+  | 2021-11-08 | ansible-core 2.12 line                |

PostgreSQL 14 minors applied as they shipped: 14.3 (2022-05-12),
14.4 (2022-06-16), 14.5 (2022-08-11), 14.6 (2022-11-10). ZooKeeper
started from 3.7.0 (2021-03-27) and moved to 3.8.0 after 2022-03-07.

## Prerequisites

- Three Ubuntu 20.04 VMs with SSH as `ubuntu` and passwordless sudo
- Python 3 on the control node
- Ansible 2.12 or newer

```
ansible-galaxy collection install -r requirements.yml
```

Edit `inventories/ha/hosts.yml` so `ansible_host` matches your VMs.
Replace the placeholder passwords in
`inventories/ha/group_vars/postgres.yml` (or encrypt
`vault.yml.example`).

## Deploy

```
# ZooKeeper quorum only
ansible-playbook playbooks/zookeeper.yml

# PostgreSQL + Patroni (requires ZooKeeper)
ansible-playbook playbooks/postgres.yml

# Full stack in order
ansible-playbook playbooks/site.yml

# Health
ansible-playbook playbooks/healthcheck.yml
scripts/cluster-status.sh
```

## Failover

See [docs/failover.md](docs/failover.md). Planned switchover:

```
patronictl -c /etc/patroni/patroni.yml switchover
```

## Inventory defaults

| Host     | Address      | ZK myid | Role at bootstrap      |
|----------|--------------|---------|------------------------|
| pg-zk-01 | 10.20.30.11  | 1       | first primary (Patroni)|
| pg-zk-02 | 10.20.30.12  | 2       | replica                |
| pg-zk-03 | 10.20.30.13  | 3       | replica                |
