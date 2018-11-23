#!/bin/bash

# Stop executing after first command fails
set -e

function printUsage {
  echo "USAGE: $0"
  echo "Atempts to stop kafka instance(s) running on this machine and cleans kafka log folders"
  exit 1
}

if [ "$#" -ne "0" ]; then
  printUsage
fi

# Location of kafka binaries
BINARY_LOCATION="${HOME}/kafka/bin"

${BINARY_LOCATION}/kafka-server-stop.sh && echo "INFO - Kafka server(s) stopped"
sleep 3
echo "INFO - Removing kafka folders"
rm -rf /tmp/xsilhar-kafka-*-logs//