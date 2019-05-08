#!/bin/bash

LOCATION="${HOME}/dp/kafka-transaction-tests"
SCRIPT="run-tests.sh"

now=$(date +"%Y-%m-%d-%H-%M")

# Run Latency Scenario with and without Same Topic Replication
${LOCATION}/${SCRIPT} -l
cd ${HOME}
mkdir latency-run-${now}
mv *latency*.out latency-run-${now}/ 2> /dev/null
cd ${LOCATION}

${LOCATION}/${SCRIPT} -l --topic-same
cd ${HOME}
mkdir latency-run-same-${now}
mv *latency*.out latency-run-same-${now}/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Latency Tests are Done" "migmig095@gmail.com" < email.msg
