#!/bin/sh

# Stop executing after first command fails
set -e

function printUsage {
  echo "USAGE: $0"
}

if [ "$#" -ne "0" ]; then
  printUsage
  exit
fi

# Location of kafka-server-start.sh binary
BINARY_LOCATION="../kafka/bin"

${BINARY_LOCATION}/kafka-server-stop.sh && echo "Kafka server(s) stopped"
sleep 3
rm -rf /tmp/xsilhar-kafka-*-logs//