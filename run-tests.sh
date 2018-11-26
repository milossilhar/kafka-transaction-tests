#!/bin/bash
set -e

function printUsage {
  echo "USAGE: $0"
  exit 1
}

if [ "$#" -ne "0" ]; then
  printUsage
fi

###############################################################
# VARIABLES
###############################################################

# Zookeeper servers
ZOOKEEPER=( "nymfe30.fi.muni.cz" )
# Zookeeper servers with ports
ZOOKEEPER_PORT=( "nymfe30.fi.muni.cz:2181" )
ZOO_LEN=${#ZOOKEEPER[@]} # length
ZOO_STR=$(IFS=,; echo "${ZOOKEEPER[*]}") # comma-separated servers
ZOO_PORT_STR=$(IFS=,; echo "${ZOOKEEPER_PORT[*]}") # comma-separated servers with ports
# Kafka servers
KAFKA=( "nymfe40.fi.muni.cz" "nymfe41.fi.muni.cz" "nymfe42.fi.muni.cz" )
# Kafka servers with ports
KAFKA_PORT=( "nymfe40.fi.muni.cz:9092" "nymfe41.fi.muni.cz:9092" "nymfe42.fi.muni.cz:9092" )
KAFKA_LEN=${#KAFKA[@]} # length
KAFKA_STR=$(IFS=,; echo "${KAFKA[*]}") # comma-separated servers
KAFKA_PORT_STR=$(IFS=,; echo "${KAFKA_PORT[*]}") # comma-separated servers with ports

# Location from which this script was executed
CMD_LOCATION=$(dirname $0)
# Location of scripts on all servers
LOCATION="${HOME}/dp/kafka-transaction-tests"

# actual date
now=$(date +"%Y-%m-%d")

# size of messages to gps topic
gps_size="50"
# name of gps topic
gps_name="gps"
# size of messages to im topic
im_size="100"
# name of im topic
im_name="im"
# size of messages to store topic
store_size="80"
# name of store topic
store_name="store"

# properties file with transactions
property_trans_file="producer-trans.properties"
# properties file with all acks
property_all_file="producer-all.properties"
# properties file with 1 acks
property_one_file="producer-1.properties"

IS_SAME_KAFKA=0
IS_SAME_ZOO=0

###############################################################
# FUNCTIONS
###############################################################

# all items of arrays are different
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

# all items of arrays are same
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

# checks if kafka servers length is legitimate
function eval_kafka_len {
  if [ $# -eq 1 ] || [ $# -eq 3 ] || [ $# -eq 5 ] || [ $# -eq 9 ]; then
    return 0
  else
    return 1
  fi
}

# checks if zookeeper servers length is legitimate
function eval_zoo_len {
  if [ $# -eq 1 ] || [ $# -eq 3 ]; then
    return 0
  else
    return 1
  fi
}

# starts kafka and zookeeper through ssh on given servers
function start_servers {
  if [ $IS_SAME_ZOO -eq "0" ]; then
    ZOO_SERVER=${ZOOKEEPER[0]}
    if [ "$ZOO_LEN" -eq "3" ]; then
      echo "CMD - ssh ${ZOO_SERVER} \"${LOCATION}/zoo-start.sh single\""
      ssh ${ZOO_SERVER} "${LOCATION}/zoo-start.sh single"
    else
      echo "CMD - ssh ${ZOO_SERVER} \"${LOCATION}/zoo-start.sh alone\""
      ssh ${ZOO_SERVER} "${LOCATION}/zoo-start.sh alone"
    fi
  else
    i=1
    for zoo in ${ZOOKEEPER[@]}; do
      echo "CMD - ssh $zoo \"${LOCATION}/zoo-start.sh multi $i\""
      ssh $zoo "${LOCATION}/zoo-start.sh multi $i"
      ((i=i+1))
    done
  fi
  
  # waits for zookeeper to initialize
  echo "INFO - Waiting for zookeeper to initialize ..."
  echo "CMD - sleep 5"
  sleep 5
  
  if [ $IS_SAME_KAFKA -eq "0" ]; then
    KAFKA_SERVER=${KAFKA}
    echo "CMD - ssh ${KAFKA_SERVER} \"${LOCATION}/kafka-start.sh --single $KAFKA_LEN ${ZOO_PORT_STR}\""
    ssh ${KAFKA_SERVER} "${LOCATION}/kafka-start.sh --single $KAFKA_LEN ${ZOO_PORT_STR}"
  else
    i=0
    for kaf in ${KAFKA[@]}; do
      echo "CMD - ssh $kaf \"${LOCATION}/kafka-start.sh $KAFKA_LEN $i ${ZOO_PORT_STR}\""
      ssh $kaf "${LOCATION}/kafka-start.sh $KAFKA_LEN $i ${ZOO_PORT_STR}"
      ((i=i+1))
    done
  fi
}

function stop_servers {
  if [ $IS_SAME_KAFKA -eq "0" ]; then
    KAFKA_SERVER=${KAFKA}
    echo "CMD - ssh ${KAFKA_SERVER} \"${LOCATION}/kafka-stop.sh\""
    ssh ${KAFKA_SERVER} "${LOCATION}/kafka-stop.sh"
  else
    for kaf in ${KAFKA[@]}; do
      echo "CMD - ssh $kaf \"${LOCATION}/kafka-stop.sh\""
      ssh $kaf "${LOCATION}/kafka-stop.sh"
    done
  fi
  
  # waits for kafka to stop
  echo "INFO - Waiting for kafka to stop ..."
  echo "CMD - sleep 5"
  sleep 5
  
  if [ $IS_SAME_ZOO -eq "0" ]; then
    ZOO_SERVER=${ZOOKEEPER[0]}
    if [ "$ZOO_LEN" -eq "3" ]; then
      echo "CMD - ssh ${ZOO_SERVER} \"${LOCATION}/zoo-stop.sh\""
      ssh ${ZOO_SERVER} "${LOCATION}/zoo-stop.sh"
    fi
  else
    for zoo in ${ZOOKEEPER[@]}; do
      echo "CMD - ssh $zoo \"${LOCATION}/zoo-stop.sh\""
      ssh $zoo "${LOCATION}/zoo-stop.sh"
    done
  fi
}

function restart_servers {
  stop_servers
  echo "CMD - sleep 10"
  sleep 10
  start_servers
  echo "INFO - Waiting for servers to initialize ..."
  echo "CMD - sleep 10"
  sleep 10
  echo "CMD - ${LOCATION}/kafka-init-topics.sh ${ZOO_PORT_STR} ${KAFKA_LEN}"
  ${LOCATION}/kafka-init-topics.sh ${ZOO_PORT_STR} ${KAFKA_LEN}
  echo "INFO - Waiting for topics to initialize ..."
  echo "CMD - sleep 2"
  sleep 2
}

###############################################################
# EVALUATE CONFIGURED SERVERS
###############################################################

if all_different ${ZOOKEEPER[@]}; then
  IS_SAME_ZOO=1
elif all_same ${ZOOKEEPER[@]}; then
  IS_SAME_ZOO=0
else
  echo "ERROR - Neither same nor different zookeeper servers set in script."
  exit 2
fi

if all_different ${KAFKA[@]}; then
  IS_SAME_KAFKA=1
elif all_same ${KAFKA[@]}; then
  IS_SAME_KAFKA=0
else
  echo "ERROR - Neither same nor different kafka servers set in script."
  exit 2
fi

if ! eval_kafka_len ${KAFKA[@]}; then
  echo "ERROR - Number of kafka servers is wrong. 1,3,5,9 expected."
  exit 3
fi
if ! eval_zoo_len ${ZOOKEEPER[@]}; then
  echo "ERROR - Number of zookeeper servers is wrong. 1,3 expected."
  exit 3
fi

###############################################################
# TEST EXECUTION
###############################################################

# compile whole project
echo "CMD - mvn -q clean install"
mvn -q clean install
# change to latency sub-project
echo "CMD - cd kafka-tests-latency"
cd kafka-tests-latency
restart_servers

# Transactional tests

## 24 000 messages, transaction 1 gps
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 24000 -m ${gps_name},1,${gps_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-1-0-0_${now}.out"
#restart_servers
## 24 000 messages, transaction 2 gps, 1 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 8000 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-2-0-1_${now}.out"
#restart_servers
## 24 000 messages, transaction 5 gps, 1 im, 2 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 3000 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-5-1-2_${now}.out"
#restart_servers
## 24 000 messages, transaction 10 gps, 2 im, 4 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1500 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-10-2-4_${now}.out"
#restart_servers
# 24 000 messages, transaction 50 gps, 10 im, 20 store
echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 300 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-50-10-20_${now}.out"
mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 300 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-50-10-20_${now}.out
#restart_servers
#
## ACK=ALL tests
#
## 24 000 messages, ack=all 1 gps
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 24000 -m ${gps_name},1,${gps_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-1-0-0_${now}.out"
#restart_servers
## 24 000 messages, ack=all 2 gps, 1 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 8000 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-2-0-1_${now}.out"
#restart_servers
## 24 000 messages, ack=all 5 gps, 1 im, 2 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 3000 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-5-1-2_${now}.out"
#restart_servers
## 24 000 messages, ack=all 10 gps, 2 im, 4 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1500 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-10-2-4_${now}.out"
#restart_servers
## 24 000 messages, ack=all 50 gps, 10 im, 20 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 300 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-50-10-20_${now}.out"
#restart_servers
#
## ACK=ONE tests
#
## 24 000 messages, ack=all 1 gps
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 24000 -m ${gps_name},1,${gps_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-1-0-0_${now}.out"
#restart_servers
## 24 000 messages, ack=all 2 gps, 1 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 8000 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-2-0-1_${now}.out"
#restart_servers
## 24 000 messages, ack=all 5 gps, 1 im, 2 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 3000 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-5-1-2_${now}.out"
#restart_servers
## 24 000 messages, ack=all 10 gps, 2 im, 4 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1500 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-10-2-4_${now}.out"
#restart_servers
## 24 000 messages, ack=all 50 gps, 10 im, 20 store
#echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 300 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-50-10-20_${now}.out"
stop_servers

# SIZE BASED tests


