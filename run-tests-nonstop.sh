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
ZOOKEEPER=( "nymfe01.fi.muni.cz" )
# Zookeeper servers with ports
ZOOKEEPER_PORT=( "nymfe01.fi.muni.cz:2181" )
ZOO_LEN=${#ZOOKEEPER[@]} # length
ZOO_STR=$(IFS=,; echo "${ZOOKEEPER[*]}") # comma-separated servers
ZOO_PORT_STR=$(IFS=,; echo "${ZOOKEEPER_PORT[*]}") # comma-separated servers with ports

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
# size of messages to replicated latency
latency_size="100"
# name of replicated latency topic
latency_name="latency"


# properties file for consumer
consumer_property="consumer.properties"
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
    echo "CMD - ssh ${ZOO_SERVER} \"${LOCATION}/zoo-stop.sh\""
    ssh ${ZOO_SERVER} "${LOCATION}/zoo-stop.sh"
  else
    for zoo in ${ZOOKEEPER[@]}; do
      echo "CMD - ssh $zoo \"${LOCATION}/zoo-stop.sh\""
      ssh $zoo "${LOCATION}/zoo-stop.sh"
    done
  fi
}

# restarts servers kafka and zookeeper on all servers
function restart_servers {
  stop_servers
  echo "CMD - sleep 10"
  sleep 10
  start_servers
  echo "INFO - Waiting for servers to initialize ..."
  echo "CMD - sleep 15"
  sleep 15
  echo "CMD - ${LOCATION}/kafka-init-topics.sh ${ZOO_PORT_STR} ${KAFKA_LEN}"
  ${LOCATION}/kafka-init-topics.sh ${ZOO_PORT_STR} ${KAFKA_LEN}
  echo "INFO - Waiting for topics to initialize ..."
  echo "CMD - sleep 5"
  sleep 5
}

# EVALUATE CONFIGURED SERVERS
function eval_servers {
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
  if ! eval_kafka_len ${KAFKA_PORT[@]}; then
    echo "ERROR - Number of kafka servers with ports is wrong. 1,3,5,9 expected."
    exit 3
  fi
  if ! eval_zoo_len ${ZOOKEEPER[@]}; then
    echo "ERROR - Number of zookeeper servers is wrong. 1,3 expected."
    exit 3
  fi
  if ! eval_zoo_len ${ZOOKEEPER_PORT[@]}; then
    echo "ERROR - Number of zookeeper servers with ports is wrong. 1,3 expected."
    exit 3
  fi
}

function set_one_kafka {
  # Kafka servers
  KAFKA=( "nymfe02.fi.muni.cz" )
  # Kafka servers with ports
  KAFKA_PORT=( "nymfe02.fi.muni.cz:9092" )
  KAFKA_LEN=${#KAFKA[@]} # length
  KAFKA_STR=$(IFS=,; echo "${KAFKA[*]}") # comma-separated servers
  KAFKA_PORT_STR=$(IFS=,; echo "${KAFKA_PORT[*]}") # comma-separated servers with ports
  eval_servers
}

# Sets variables for three kafka servers
function set_three_kafka {
  # Kafka servers
  KAFKA=( "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" )
  # Kafka servers with ports
  KAFKA_PORT=( "nymfe02.fi.muni.cz:9092" "nymfe02.fi.muni.cz:9093" "nymfe02.fi.muni.cz:9094" )
  KAFKA_LEN=${#KAFKA[@]} # length
  KAFKA_STR=$(IFS=,; echo "${KAFKA[*]}") # comma-separated servers
  KAFKA_PORT_STR=$(IFS=,; echo "${KAFKA_PORT[*]}") # comma-separated servers with ports
  eval_servers
}

# Sets variables for five kafka servers
function set_five_kafka {
  # Kafka servers
  KAFKA=( "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" )
  # Kafka servers with ports
  KAFKA_PORT=( "nymfe02.fi.muni.cz:9092" "nymfe02.fi.muni.cz:9093" "nymfe02.fi.muni.cz:9094" "nymfe02.fi.muni.cz:9095" "nymfe02.fi.muni.cz:9096" )
  KAFKA_LEN=${#KAFKA[@]} # length
  KAFKA_STR=$(IFS=,; echo "${KAFKA[*]}") # comma-separated servers
  KAFKA_PORT_STR=$(IFS=,; echo "${KAFKA_PORT[*]}") # comma-separated servers with ports
  eval_servers
}

# Sets variables for nine kafka servers
function set_nine_kafka {
  # Kafka servers
  KAFKA=( "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" "nymfe02.fi.muni.cz" )
  # Kafka servers with ports
  KAFKA_PORT=( "nymfe02.fi.muni.cz:9092" "nymfe02.fi.muni.cz:9093" "nymfe02.fi.muni.cz:9094" "nymfe02.fi.muni.cz:9095" "nymfe02.fi.muni.cz:9096" "nymfe02.fi.muni.cz:9097" "nymfe02.fi.muni.cz:9098" "nymfe02.fi.muni.cz:9099" "nymfe02.fi.muni.cz:9100" )
  KAFKA_LEN=${#KAFKA[@]} # length
  KAFKA_STR=$(IFS=,; echo "${KAFKA[*]}") # comma-separated servers
  KAFKA_PORT_STR=$(IFS=,; echo "${KAFKA_PORT[*]}") # comma-separated servers with ports
  eval_servers
}

# Prints kafka variables 
function print_kafka_servers {
  echo "INFO - var: KAFKA = ${KAFKA}"
  echo "INFO - var: KAFKA_PORT = ${KAFKA_PORT}"
  echo "INFO - var: KAFKA_LEN = ${KAFKA_LEN}"
  echo "INFO - var: KAFKA_STR = ${KAFKA_STR}"
  echo "INFO - var: KAFKA_PORT_STR = ${KAFKA_PORT_STR}"
}

###############################################################
# TEST PREPARATION
###############################################################

# FUNCTIONS FOR TESTS

# Transactional tests
function transactional_tests {
  # restarts servers
  restart_servers
  
  # 3120 messages, transactional 1 gps
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 3120 -m ${gps_name},1,${gps_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-1-0-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 3120 -m ${gps_name},1,${gps_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-1-0-0_${now}.out
  restart_servers
  
  # 3120 messages, transactional 2 gps, 1 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1040 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-2-0-1_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1040 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-2-0-1_${now}.out
  restart_servers

  # 3120 messages, transactional 5 gps, 1 im, 2 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 390 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-5-1-2_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 390 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-5-1-2_${now}.out
  restart_servers

  # 3120 messages, transactional 10 gps, 2 im, 4 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 195 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-10-2-4_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 195 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-10-2-4_${now}.out
  restart_servers

  # 3120 messages, transactional 50 gps, 10 im, 20 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 39 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-50-10-20_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 39 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-trans-result-50-10-20_${now}.out
  restart_servers

  # ACK=ALL tests

  # 3120 messages, ack=all 1 gps
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 3120 -m ${gps_name},1,${gps_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-1-0-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 3120 -m ${gps_name},1,${gps_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-1-0-0_${now}.out
  restart_servers
  
  # 3120 messages, ack=all 2 gps, 1 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1040 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-2-0-1_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1040 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-2-0-1_${now}.out
  restart_servers
  
  # 3120 messages, ack=all 5 gps, 1 im, 2 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 390 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-5-1-2_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 390 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-5-1-2_${now}.out
  restart_servers
  
  # 3120 messages, ack=all 10 gps, 2 im, 4 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 195 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-10-2-4_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 195 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-10-2-4_${now}.out
  restart_servers
  
  # 3120 messages, ack=all 50 gps, 10 im, 20 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 39 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-50-10-20_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 39 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-all-result-50-10-20_${now}.out
  restart_servers

  # ACK=ONE tests

  # 3120 messages, ack=1 1 gps
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 3120 -m ${gps_name},1,${gps_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-1-0-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 3120 -m ${gps_name},1,${gps_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-1-0-0_${now}.out
  restart_servers
  
  # 3120 messages, ack=1 2 gps, 1 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1040 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-2-0-1_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1040 -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-2-0-1_${now}.out
  restart_servers
  
  # 3120 messages, ack=1 5 gps, 1 im, 2 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 390 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-5-1-2_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 390 -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-5-1-2_${now}.out
  restart_servers
  
  # 3120 messages, ack=1 10 gps, 2 im, 4 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 195 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-10-2-4_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 195 -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-10-2-4_${now}.out
  restart_servers
  
  # 3120 messages, ack=1 50 gps, 10 im, 20 store
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 39 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}\" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-50-10-20_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 39 -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}" | tee ${HOME}/${KAFKA_LEN}server-producer-one-result-50-10-20_${now}.out
}

# SIZE BASED tests
function size_tests {
  # restart servers
  restart_servers
  
  # Transactional Tests
  
  # 1000 messages, transactional, size=5MB
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,5242880\" | tee ${HOME}/${KAFKA_LEN}server-size-trans-5MB-0-1-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,5242880" | tee ${HOME}/${KAFKA_LEN}server-size-trans-5MB-0-1-0_${now}.out
  restart_servers
  
  # 1000 messages, transactional, size=1MB
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,1048576\" | tee ${HOME}/${KAFKA_LEN}server-size-trans-1MB-0-1-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,1048576" | tee ${HOME}/${KAFKA_LEN}server-size-trans-1MB-0-1-0_${now}.out
  restart_servers
  
  # 1000 messages, transactional, size=500kB
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,512000\" | tee ${HOME}/${KAFKA_LEN}server-size-trans-500kB-0-1-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,512000" | tee ${HOME}/${KAFKA_LEN}server-size-trans-500kB-0-1-0_${now}.out
  restart_servers
  
  # 1000 messages, transactional, size=200kB
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,204800\" | tee ${HOME}/${KAFKA_LEN}server-size-trans-200kB-0-1-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,204800" | tee ${HOME}/${KAFKA_LEN}server-size-trans-200kB-0-1-0_${now}.out
  restart_servers
  
  # 1000 messages, transactional, size=100kB
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,102400\" | tee ${HOME}/${KAFKA_LEN}server-size-trans-100kB-0-1-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,102400" | tee ${HOME}/${KAFKA_LEN}server-size-trans-100kB-0-1-0_${now}.out
  restart_servers
  
  # 1000 messages, transactional, size=50kB
  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,51200\" | tee ${HOME}/${KAFKA_LEN}server-size-trans-50kB-0-1-0_${now}.out"
  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_trans_file} -n 1000 -m ${im_name},1,51200" | tee ${HOME}/${KAFKA_LEN}server-size-trans-50kB-0-1-0_${now}.out
  restart_servers
  
  # ACKS=ALL tests
  
#  # 1000 messages, ack=all, size=5MB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,5242880\" | tee ${HOME}/${KAFKA_LEN}server-size-all-5MB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,5242880" | tee ${HOME}/${KAFKA_LEN}server-size-all-5MB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=all, size=1MB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,1048576\" | tee ${HOME}/${KAFKA_LEN}server-size-all-1MB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,1048576" | tee ${HOME}/${KAFKA_LEN}server-size-all-1MB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=all, size=500kB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,512000\" | tee ${HOME}/${KAFKA_LEN}server-size-all-500kB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,512000" | tee ${HOME}/${KAFKA_LEN}server-size-all-500kB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=all, size=200kB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,204800\" | tee ${HOME}/${KAFKA_LEN}server-size-all-200kB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,204800" | tee ${HOME}/${KAFKA_LEN}server-size-all-200kB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=all, size=100kB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,102400\" | tee ${HOME}/${KAFKA_LEN}server-size-all-100kB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,102400" | tee ${HOME}/${KAFKA_LEN}server-size-all-100kB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=all, size=50kB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,51200\" | tee ${HOME}/${KAFKA_LEN}server-size-all-50kB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_all_file} -n 1000 -m ${im_name},1,51200" | tee ${HOME}/${KAFKA_LEN}server-size-all-50kB-0-1-0_${now}.out
#  restart_servers
  
  # ACKS=1 tests
  
#  # 1000 messages, ack=one, size=5MB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,5242880\" | tee ${HOME}/${KAFKA_LEN}server-size-one-5MB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,5242880" | tee ${HOME}/${KAFKA_LEN}server-size-one-5MB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=one, size=1MB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,1048576\" | tee ${HOME}/${KAFKA_LEN}server-size-one-1MB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,1048576" | tee ${HOME}/${KAFKA_LEN}server-size-one-1MB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=one, size=500kB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,512000\" | tee ${HOME}/${KAFKA_LEN}server-size-one-500kB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,512000" | tee ${HOME}/${KAFKA_LEN}server-size-one-500kB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=one, size=200kB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,204800\" | tee ${HOME}/${KAFKA_LEN}server-size-one-200kB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,204800" | tee ${HOME}/${KAFKA_LEN}server-size-one-200kB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=one, size=100kB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,102400\" | tee ${HOME}/${KAFKA_LEN}server-size-one-100kB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,102400" | tee ${HOME}/${KAFKA_LEN}server-size-one-100kB-0-1-0_${now}.out
#  restart_servers
#  
#  # 1000 messages, ack=one, size=50kB
#  echo "CMD - mvn -q exec:java -Dexec.args=\"-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,51200\" | tee ${HOME}/${KAFKA_LEN}server-size-one-50kB-0-1-0_${now}.out"
#  mvn -q exec:java -Dexec.args="-P -s ${KAFKA_PORT_STR} -p ${property_one_file} -n 1000 -m ${im_name},1,51200" | tee ${HOME}/${KAFKA_LEN}server-size-one-50kB-0-1-0_${now}.out
}

# Latency tests
function latency_tests {
  # restart servers
  restart_servers
  
  # 2000 messages, transactional
  echo "CMD - mvn -q exec:java -Dexec.args=\"-s ${KAFKA_PORT_STR} -p ${property_trans_file} -c ${consumer_property} -n 2000 -m ${latency_name},1,${latency_size}\" | tee ${HOME}/${KAFKA_LEN}server-latency-trans-result_${now}.out"
  mvn -q exec:java -Dexec.args="-s ${KAFKA_PORT_STR} -p ${property_trans_file} -c ${consumer_property} -n 2000 -m ${latency_name},1,${latency_size}" | tee ${HOME}/${KAFKA_LEN}server-latency-trans-result_${now}.out
  restart_servers
  
  # 2000 messages, ack=all
  echo "CMD - mvn -q exec:java -Dexec.args=\"-s ${KAFKA_PORT_STR} -p ${property_all_file} -c ${consumer_property} -n 2000 -m ${latency_name},1,${latency_size}\" | tee ${HOME}/${KAFKA_LEN}server-latency-all-result_${now}.out"
  mvn -q exec:java -Dexec.args="-s ${KAFKA_PORT_STR} -p ${property_all_file} -c ${consumer_property} -n 2000 -m ${latency_name},1,${latency_size}" | tee ${HOME}/${KAFKA_LEN}server-latency-all-result_${now}.out
  restart_servers
  
  # 2000 messages, ack=1
  echo "CMD - mvn -q exec:java -Dexec.args=\"-s ${KAFKA_PORT_STR} -p ${property_one_file} -c ${consumer_property} -n 2000 -m ${latency_name},1,${latency_size}\" | tee ${HOME}/${KAFKA_LEN}server-latency-one-result_${now}.out"
  mvn -q exec:java -Dexec.args="-s ${KAFKA_PORT_STR} -p ${property_one_file} -c ${consumer_property} -n 2000 -m ${latency_name},1,${latency_size}" | tee ${HOME}/${KAFKA_LEN}server-latency-one-result_${now}.out
}

###############################################################
# TEST EXECUTION
###############################################################

# compile whole project
echo "CMD - mvn -q clean install"
mvn -q clean install

# change to latency sub-project
echo "CMD - cd kafka-tests-latency"
cd kafka-tests-latency

# Sets execution for 1 kafka servers
set_one_kafka
# Prints actual configuration
print_kafka_servers
# Runs transactional tests
transactional_tests
# Runs size based tests
size_tests
# Runs latency tests
latency_tests

# Sets execution for 3 kafka servers
set_three_kafka
# Prints actual configuration
print_kafka_servers
# Runs transactional tests
transactional_tests
# Runs size based tests
size_tests
# Runs latency tests
latency_tests

# Sets execution for 5 kafka servers
set_five_kafka
# Prints actual configuration
print_kafka_servers
# Runs transactional tests
transactional_tests
# Runs size based tests
size_tests
# Runs latency tests
latency_tests

# Sets execution for 9 kafka servers
set_nine_kafka
# Prints actual configuration
print_kafka_servers
# Runs transactional tests
transactional_tests
# Runs size based tests
size_tests
# Runs latency tests
latency_tests

# Stops servers
stop_servers

