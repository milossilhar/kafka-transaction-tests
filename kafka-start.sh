#!/bin/sh

# Stop executing after first command fails
set -e

function printUsage {
  echo "USAGE: $0 [-s|--single] 3|5|9 0-2|0-4|0-9"
  echo "-s            run on single machine, ignores instance"
  echo "3|5|9         number of servers to start"
  echo "0-2|0-4|0-9   particular instance of server to start"
}

case $1 in
-s | --single)
  SINGLE="0"
  CONFIG_BASE="single"
  NUM_SERVERS="$2"
  INSTANCE="0"
  ;;
*)
  SINGLE="1"
  CONFIG_BASE="server"
  NUM_SERVERS="$1"
  INSTANCE="$2"
  ;;
esac

if [ "$#" -ne "2" -a "$#" -ne "3" ] || [ "$NUM_SERVERS" -le "$INSTANCE" ] || [ "$INSTANCE" -lt "0" ]; then
  printUsage
  exit
fi

# Location of kafka-server-start.sh binary
BINARY_LOCATION="../kafka/bin"
# Where are configs located
CONFIGS_LOCATION="./configs"
# Common name for directory of all configurations
CONFIGS_LOCATION_BASE="kafka-configs-"
# Common name for all files of configs
CONFIGS_FILE=$(printf %s-%02d-%02d.properties $CONFIG_BASE $NUM_SERVERS $INSTANCE)

if [ $SINGLE -eq "0" ]; then
  for (( i=0; i<${NUM_SERVERS}; i++ )); do
    CONFIGS_FILE=$(printf %s-%02d-%02d.properties $CONFIG_BASE $NUM_SERVERS $i)
    ${BINARY_LOCATION}/kafka-server-start.sh -daemon ${CONFIGS_LOCATION}/${CONFIGS_LOCATION_BASE}${NUM_SERVERS}/${CONFIGS_FILE} && echo "Kafka server $i started"
  done
else
  ${BINARY_LOCATION}/kafka-server-start.sh -daemon ${CONFIGS_LOCATION}/${CONFIGS_LOCATION_BASE}${NUM_SERVERS}/${CONFIGS_FILE} && echo "Kafka server $INSTANCE/$NUM_SERVERS started"
fi
