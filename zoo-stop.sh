#!/bin/bash

# Stop executing after first command fails
set -e

function printUsage {
  echo "USAGE: $0"
  echo "Atempts to stop zookeeper instance running on this machine and cleans zookeeper configuration folders."
}

if [ "$#" -ne "0" ]; then
  printUsage
  exit
fi

# Location of kafka-server-start.sh binary
BINARY_LOCATION="../kafka/bin"

${BINARY_LOCATION}/zookeeper-server-stop.sh && echo "Zookeeper instance(s) stopped"
rm -rf /tmp/xsilhar-zookeeper//