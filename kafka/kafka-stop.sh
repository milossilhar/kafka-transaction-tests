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

# Location from which this script was executed
CMD_LOCATION=$(dirname $0)
# Location of kafka-topics.sh binary
BINARY_LOCATION="${CMD_LOCATION}/bin"

${BINARY_LOCATION}/kafka-server-stop.sh && echo "INFO - Kafka server(s) stopped"
sleep 1
echo "INFO - Removing kafka folders"
rm -rf /tmp/xsilhar-kafka-*-logs/