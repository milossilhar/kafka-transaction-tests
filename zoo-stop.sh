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

# Location of kafka binaries
BINARY_LOCATION="${HOME}/kafka/bin"

${BINARY_LOCATION}/zookeeper-server-stop.sh && echo "Zookeeper instance(s) stopped"
sleep 3
rm -rf /tmp/xsilhar-zookeeper//