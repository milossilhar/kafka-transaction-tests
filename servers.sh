#!/bin/bash

function printUsage {
  echo "USAGE: $0"
  echo "start     starts servers on configured machines"
  echo "stop      stops servers on configured machines"
}

function all_different {
  array=("$@")
  aLen=${#array[@]}
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
  if [ $# -eq 3 ] || [ $# -eq 5 ] || [ $# -eq 9 ]; then
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

ZOOKEEPER=("nymfe01.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe03.fi.muni.cz")
KAFKA=("nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz")

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
  echo "Fatal ERROR: Number of kafka servers is wrong."
  exit 3
fi
if ! eval_zoo_len ${ZOOKEEPER[@]}; then
  echo "Fatal ERROR: Number of zookeeper servers is wrong."
  exit 3
fi

if [ $IS_SAME_ZOO -eq "0" ]; then
  ZOO_SERVER=${ZOOKEEPER[0]}
  ssh $ZOO_SERVER <<ENDSSH
  cd ~/dp
  ./kafka/bin/zookeeper-server-start.sh -daemon ./kafka-transaction-tests/configs/zookeeper_single.properties
  ENDSSH
else
  for zoo in ${ZOOKEEPER[@]}; do
    
  done
fi


