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
- Patroni 4.0.6 on 8008
- PostgreSQL 16.10 on 5432

## Recently added

**PostgreSQL 16 (Sep 2025)**

- Bumped to PostgreSQL 16.10 and Patroni 4.0.6
- Guests moved to Ubuntu 22.04 (`focal-pgdg` is gone from PGDG)
- `pg_hba` uses `scram-sha-256`
- PGDG suite check in the `postgresql` role

**Ops and lab (Sep 2026)**

- `Makefile` — `make deploy`, `make healthcheck`, `make status`, …
- `Vagrantfile` for a local three-node lab
- ZooKeeper tarball SHA-512 keyed by version

**Fixes (Sep 2026)**

- Drop the apt-created `main` cluster before Patroni bootstraps
- Health checks assert ZK quorum (`mntr`) and one Patroni primary
- Patroni sees `PGDATA` / `bin_dir` via shared group vars

Not yet run end-to-end against live VMs in CI. Use `make lab &&
make deploy && make healthcheck` to validate on your side.

## Versions

| Component   | Pin    | Released   | Why this line                          |
|-------------|--------|------------|----------------------------------------|
| Ubuntu      | 22.04  | 2022-04-21 | PGDG dropped focal; jammy-pgdg is live |
| PostgreSQL  | 16.10  | 2025-08-14 | Latest 16 minor at time of this change |
| Patroni     | 4.0.6  | 2025-06-06 | PG16 needs >= 3.0.3 plus rewind fixes  |
| kazoo       | 2.10.0 | 2024-01-28 | Patroni ZooKeeper DCS client           |
| ZooKeeper   | 3.8.0  | 2022-03-07 | Ensemble binary, checksum pinned       |
| OpenJDK     | 11     | LTS        | Required by ZooKeeper 3.8              |
| Ansible     | 2.12+  | 2021-11-08 | ansible-core 2.12 or newer             |

Ubuntu 20.04 is no longer usable: `apt.postgresql.org` has removed
`focal-pgdg`, so the repository 404s. The role checks
`ansible_distribution_release` against the suites PGDG still
publishes and fails with that explanation rather than an apt error.

The commit history walks the 2022 stack this repo started from
(PostgreSQL 14.3 through 14.6, ZooKeeper 3.7.0 then 3.8.0), with
each pin matching a release that had actually shipped at the time.

## Prerequisites

- Three Ubuntu 22.04 VMs with SSH as `ubuntu` and passwordless sudo
- Python 3 on the control node
- Ansible 2.12 or newer

```
ansible-galaxy collection install -r requirements.yml
```

Local three-node lab (VirtualBox):

```
vagrant up
ansible-playbook playbooks/site.yml -e ansible_user=vagrant \
  -e ansible_ssh_private_key_file="$HOME/.vagrant.d/insecure_private_key"
```

Edit `inventories/ha/hosts.yml` so `ansible_host` matches your VMs.
Replace the placeholder passwords in
`inventories/ha/group_vars/postgres.yml` (or encrypt
`vault.yml.example`).

## Deploy

`make` wraps the playbooks; `make` on its own lists every target.

```
make deps          # install required collections
make syntax        # syntax-check all playbooks
make zookeeper     # ensemble only
make postgres      # PostgreSQL + Patroni (requires quorum)
make deploy        # full stack, in order
make healthcheck   # assert quorum and a single primary
make status        # raw ZooKeeper / Patroni output
```

Pass Ansible flags through `FLAGS`, and point at another inventory
with `INVENTORY`:

```
make healthcheck INVENTORY=inventories/staging/hosts.yml
make deploy FLAGS="--limit pg-zk-01 --check"
```

The playbooks work equally well on their own:

```
ansible-playbook playbooks/site.yml
ansible-playbook playbooks/healthcheck.yml
```

## Health

`make healthcheck` is a real gate, not a report. It fails when
ZooKeeper has no voting majority, when no node is `leader`, or when
Patroni does not show exactly one primary with every member
`running`. `ruok` alone is not enough: a node stuck in `LOOKING`
with no quorum still answers `imok`, so the check reads
`zk_server_state` from `mntr` instead.

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
