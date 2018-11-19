#!/bin/sh

# Stop executing after first command fails
set -e

function printUsage {
  echo "USAGE: $0 alone|single|multi"
  echo "alone           runs standalone instance of zookeeper as daemon"
  echo "single          runs replicated zookeeper on single server as daemons"
  echo "mutli [myid]    runs one of three instances of replicated zookeeper as daemon"
}

if [ "$#" -ne "1" ]; then
  printUsage
  exit
fi

# Zookeeper folder
DATA_DIR="/tmp/xsilhar-zookeeper"
# Location of kafka-server-start.sh binary
BINARY_LOCATION="../kafka/bin"
# Where are configs located
CONFIGS_LOCATION="./configs"

case $1 in
"alone")
  ${BINARY_LOCATION}/zookeeper-server-start.sh -daemon ${CONFIGS_LOCATION}/zookeeper_alone.properties && echo "Zookeeper standalone server started"
  ;;
"single")
  mkdir $DATA_DIR
  mkdir $DATA_DIR/server1
  mkdir $DATA_DIR/server2
  mkdir $DATA_DIR/server3
  echo "1">$DATA_DIR/server1/myid
  echo "2">$DATA_DIR/server2/myid
  echo "3">$DATA_DIR/server3/myid
  ${BINARY_LOCATION}/zookeeper-server-start.sh -daemon ${CONFIGS_LOCATION}/zookeeper_replica_01.properties && echo "Zookeeper server 1 started"
  ${BINARY_LOCATION}/zookeeper-server-start.sh -daemon ${CONFIGS_LOCATION}/zookeeper_replica_02.properties && echo "Zookeeper server 2 started"
  ${BINARY_LOCATION}/zookeeper-server-start.sh -daemon ${CONFIGS_LOCATION}/zookeeper_replica_03.properties && echo "Zookeeper server 3 started"
  ;;
"multi")
  mkdir $DATA_DIR  
  echo "$2">$DATA_DIR/myid
  ${BINARY_LOCATION}/zookeeper-server-start.sh -daemon ${CONFIGS_LOCATION}/zookeeper_replica.properties && echo "Zookeeper replicated server $2 started"
  ;;
*)
  printUsage
  exit
  ;;
esac
