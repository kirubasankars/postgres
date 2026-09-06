# Failover runbook

## Automatic failover

If the current primary stops heartbeating, Patroni uses the ZooKeeper
lock to elect a replica. Clients should reconnect (or talk through a
proxy) after the new primary's REST `/primary` endpoint returns 200.

Check the cluster:

```
ansible-playbook playbooks/healthcheck.yml
scripts/cluster-status.sh
```

## Planned switchover

On any node:

```
patronictl -c /etc/patroni/patroni.yml list
patronictl -c /etc/patroni/patroni.yml switchover --master pg-zk-01 --candidate pg-zk-02
```

Confirm ZooKeeper still has a leader (`echo srvr | nc 127.0.0.1 2181`)
before switching. A ZooKeeper minority (2 of 3 down) blocks failover
because the DCS lock cannot be updated.

## Rejoining a former primary

1. Fix the host and start ZooKeeper.
2. Start Patroni. With `use_pg_rewind: true` it should rewind and
   follow the new primary.
3. If rewind fails, remove `PGDATA` and let Patroni reclone.

## ZooKeeper loss

Losing one ZK node is fine. Losing two nodes freezes leader elections
even if PostgreSQL replicas are healthy. Restore a voter before trying
another switchover.
