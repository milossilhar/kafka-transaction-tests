#!/bin/bash

# Stop executing after first command fails
set -e

function printUsage {
  echo "USAGE: $0"
  echo "Atempts to stop zookeeper instance running on this machine and cleans zookeeper configuration folders"
  exit 1
}

if [ "$#" -ne "0" ]; then
  printUsage
fi

# Location from which this script was executed
CMD_LOCATION=$(dirname $0)
# Location of kafka-topics.sh binary
BINARY_LOCATION="${CMD_LOCATION}/bin"

${BINARY_LOCATION}/zookeeper-server-stop.sh && echo "INFO - Zookeeper instance(s) stopped"
sleep 1
echo "INFO - Removing zookeeper folders"
rm -rf /tmp/xsilhar-zookeeper/