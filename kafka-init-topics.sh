#!/bin/bash

# Stop executing after first command fails
set -e

function printUsage {
  echo "USAGE: $0 [zookeeper_server] [1|3|5|9]"
  echo "zookeeper_server    zookeeper connection in the form host:port"
  echo "                    multiple hosts can be given to allow fail-over"
  echo "1|3|5|9             number of running instances of kafka"
  exit 1
}

if [ "$#" -ne "2" ]; then
  printUsage
fi

case $2 in
1)
  factor="1"
  partitions="2"
  ;;
3)
  factor="3"
  partitions="6"
  ;;
5)
  factor="5"
  partitions="10"
  ;;
9)
  factor="9"
  partitions="18"
  ;;
*)
  printUsage
  exit 1
  ;;
esac

# Location of kafka-topics.sh binary
BINARY_LOCATION="${HOME}/kafka/bin"

${BINARY_LOCATION}/kafka-topics.sh --create --zookeeper ${1} --topic gps --partitions ${partitions} --replication-factor ${factor}
${BINARY_LOCATION}/kafka-topics.sh --create --zookeeper ${1} --topic im --partitions ${partitions} --replication-factor ${factor}
${BINARY_LOCATION}/kafka-topics.sh --create --zookeeper ${1} --topic store --partitions ${partitions} --replication-factor ${factor}
