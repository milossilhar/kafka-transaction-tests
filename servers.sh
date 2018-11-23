#!/bin/bash
set -e

function printUsage {
  echo "USAGE: $0 start|stop"
  echo "start     starts servers on configured machines"
  echo "stop      stops servers on configured machines"
  exit 1
}

function all_different {
  array=("$@")
  aLen=${#array[@]}
  if [ "$aLen" -eq "1" ]; then
    return 1
  fi
  for (( i=0; i<${aLen}; i++ )); do
    for (( j=$i+1; j<${aLen}; j++ )); do
      if [ "${array[$i]}" = "${array[$j]}" ]; then
        return 1
      fi
    done
  done
  return 0
}

function all_same {
  array=("$@")
  aLen=${#array[@]}
  for (( i=0; i<${aLen}; i++ )); do
    for (( j=$i+1; j<${aLen}; j++ )); do
      if [ "${array[$i]}" != "${array[$j]}" ]; then
        return 1
      fi
    done
  done
  return 0
}

function eval_kafka_len {
  if [ $# -eq 1 ] || [ $# -eq 3 ] || [ $# -eq 5 ] || [ $# -eq 9 ]; then
    return 0
  else
    return 1
  fi
}

function eval_zoo_len {
  if [ $# -eq 1 ] || [ $# -eq 3 ]; then
    return 0
  else
    return 1
  fi
}

if [ "$#" -ne "1" ]; then
  printUsage
fi

LOCATION="~/kafka-transaction-tests"
ZOOKEEPER=("localhost")
ZOO_LEN=${#ZOOKEEPER[@]}
ZOO_STR=$(IFS=,; echo "${ZOOKEEPER[*]}")
KAFKA=("localhost")
KAFKA_LEN=${#KAFKA[@]}
KAFKA_STR=$(IFS=,; echo "${KAFKA[*]}")

if all_different ${ZOOKEEPER[@]}; then
  IS_SAME_ZOO=1
elif all_same ${ZOOKEEPER[@]}; then
  IS_SAME_ZOO=0
else
  echo "Fatal ERROR: Neither same nor different zookeeper servers set in script."
  exit 2
fi

if all_different ${KAFKA[@]}; then
  IS_SAME_KAFKA=1
elif all_same ${KAFKA[@]}; then
  IS_SAME_KAFKA=0
else
  echo "Fatal ERROR: Neither same nor different kafka servers set in script."
  exit 2
fi

if ! eval_kafka_len ${KAFKA[@]}; then
  echo "Fatal ERROR: Number of kafka servers is wrong. 1,3,5,9 expected."
  exit 3
fi
if ! eval_zoo_len ${ZOOKEEPER[@]}; then
  echo "Fatal ERROR: Number of zookeeper servers is wrong. 1,3 expected."
  exit 3
fi

case $1 in
start)
  if [ $IS_SAME_KAFKA -eq "0" ]; then
    KAFKA_SERVER=${KAFKA}
    echo "ssh ${KAFKA_SERVER} \"$LOCATION/kafka-start.sh --single $KAFKA_LEN\""
  else
    i=1
    for kaf in ${KAFKA[@]}; do
      echo "ssh $kaf \"$LOCATION/kafka-start.sh $KAFKA_LEN $i\""
      ((i=i+1))
    done
  fi
  
  if [ $IS_SAME_ZOO -eq "0" ]; then
    ZOO_SERVER=${ZOOKEEPER[0]}
    if [ "$ZOO_LEN" -eq "3" ]; then
      echo "ssh ${ZOO_SERVER} \"$LOCATION/zoo-start.sh single\""
    else
      echo "ssh ${ZOO_SERVER} \"$LOCATION/zoo-start.sh alone\""
    fi
  else
    i=1
    for zoo in ${ZOOKEEPER[@]}; do
      echo "ssh $zoo \"$LOCATION/zoo-start.sh multi $i\""
      ((i=i+1))
    done
  fi
  ;;
stop)
  if [ $IS_SAME_KAFKA -eq "0" ]; then
    KAFKA_SERVER=${KAFKA}
    echo "ssh ${KAFKA_SERVER} \"$LOCATION/kafka-stop.sh\""
  else
    for kaf in ${KAFKA[@]}; do
      echo "ssh $kaf \"$LOCATION/kafka-stop.sh\""
    done
  fi
  
  if [ $IS_SAME_ZOO -eq "0" ]; then
    ZOO_SERVER=${ZOOKEEPER[0]}
    if [ "$ZOO_LEN" -eq "3" ]; then
      echo "ssh ${ZOO_SERVER} \"$LOCATION/zoo-stop.sh\""
    fi
  else
    for zoo in ${ZOOKEEPER[@]}; do
      echo "ssh $zoo \"$LOCATION/zoo-stop.sh\""
    done
  fi
  ;;
*)
  printUsage
  ;;
esac


