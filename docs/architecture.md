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

PostgreSQL stays on the 14 series. 15.0 shipped 2022-10-13; moving
a live HA cluster across a major version is a separate project.

| Minor | Released   |
|-------|------------|
| 14.1  | 2021-11-11 |
| 14.2  | 2022-02-10 |
| 14.3  | 2022-05-12 |
| 14.4  | 2022-06-16 |
| 14.5  | 2022-08-11 |
