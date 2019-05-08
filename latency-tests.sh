#!/bin/bash
set -e

LOCATION="${HOME}/dp/kafka-transaction-tests"
SCRIPT="run-tests.sh"

now=$(date +"%Y-%m-%d-%H-%M")

# Run Latency Scenario with and without Same Topic Replication
${LOCATION}/${SCRIPT} -l
cd ${HOME}
mkdir latency-run-${now}
if [ -e *latency*.out ]; then
  mv *latency*.out ./latency-run-${now}/
fi
cd ${LOCATION}

${LOCATION}/${SCRIPT} -l --topic-same
cd ${HOME}
mkdir latency-run-same-${now}
if [ -e *latency*.out ]; then
  mv *latency*.out ./latency-run-same-${now}/
fi
cd ${LOCATION}

mailx -s "Latency Tests are Done" "migmig095@gmail.com" < email.msg
