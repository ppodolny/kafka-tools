#!/usr/bin/env python


import sys
from kazoo.client import KazooClient
from text_collector import add_metric, commit, push_commit


sys.path.append('/opt/prometheus/node_exporter')
kafka_conf = '/etc/kafka/server.properties'
zk_broker_path = '/brokers/ids'
zk_conn_string = str([ line for line in open(kafka_conf) if 'zookeeper.connect=' in line ][0])
kafka_id = [ line for line in open(kafka_conf) if 'broker.id=' in line ][0].split("=")[1].strip("\n")


#########################################
SUBJECT="kafka_broker_in_zk"
#########################################


def main():
  # connect to zk
  zk = KazooClient(hosts=zk_conn_string)
  zk.start()
  children = zk.get_children(zk_broker_path)
  if kafka_id in children:
    #ok
    add_metric(SUBJECT,'kafka_broker_in_zk','gauge',1)
  else
    #not ok
    add_metric(SUBJECT,'kafka_broker_in_zk','gauge',0)
  push_commit(SUBJECT,'ops-data')

if __name__ == '__main__':
  main()
