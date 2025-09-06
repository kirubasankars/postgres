# Architecture

Three Linux VMs share two roles: a ZooKeeper voter and a Patroni
PostgreSQL member.

```
          +-----------+     +-----------+     +-----------+
          | pg-zk-01  |     | pg-zk-02  |     | pg-zk-03  |
          | ZK :2181  |<--->| ZK :2181  |<--->| ZK :2181  |
          | Patroni   |     | Patroni   |     | Patroni   |
          | Postgres  |---->| Postgres  |---->| Postgres  |
          +-----------+     +-----------+     +-----------+
               ^                  ^                  ^
               |     streaming replication (primary -> replicas)
```

## ZooKeeper

The ensemble is a 3-voter quorum (`server.1` / `server.2` / `server.3`).
Patroni stores the leader lock and cluster configuration here (DCS).
A single VM outage still leaves a majority.

Versions used in this repo track upstream release dates:

| Version | Released   | Notes                          |
|---------|------------|--------------------------------|
| 3.7.0   | 2021-03-27 | Starting pin in January 2022   |
| 3.8.0   | 2022-03-07 | Current ensemble binary        |

## PostgreSQL + Patroni

Patroni starts `postgres`, runs `initdb` on the first primary, and
uses `pg_basebackup` plus replication slots for the two standbys.
`pg_rewind` is enabled so a former primary can rejoin as a replica.

The cluster runs PostgreSQL 16.10 (2025-08-14), the current 16
minor at the time of this change, with Patroni 4.0.6. Patroni only
gained PostgreSQL 16 support in 3.0.3 and fixed `pg_rewind` against
v16+ later in the 3.x series, so the 2.1.x line this repo started
with cannot drive a 16 cluster.

| Minor | Released   |
|-------|------------|
| 16.0  | 2023-09-14 |
| 16.9  | 2025-05-08 |
| 16.10 | 2025-08-14 |

The repo previously tracked the 14 series (14.1 in 2021-11-11
through 14.6 in 2022-11-10), which reaches end of life on
2026-11-12.

### Major upgrades

`postgresql_version` selects the package, PGDATA, and `bin_dir`, so
changing it only describes a *new* cluster. An existing cluster
still needs `pg_upgrade` or a logical dump; Patroni will not cross
major versions in place.
