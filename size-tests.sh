#!/bin/bash

LOCATION="${HOME}/dp/kafka-transaction-tests"
SCRIPT="run-tests.sh"

now=$(date +"%Y-%m-%d-%H-%M")

# Run 3 times Size Scenario with Same Topic Replication
#${LOCATION}/${SCRIPT} -s --topic-same
#cd ${HOME}
#mkdir size-run-same-${now}-1
#mv *size*.out ./size-run-same-${now}-1/ 2> /dev/null
#cd ${LOCATION}
#
#echo "CMD - Sending Notification E-Mail."
#mailx -s "Size Tests Same 1/3 Done" "migmig095@gmail.com" < email.msg
#
#${LOCATION}/${SCRIPT} -s --topic-same
#cd ${HOME}
#mkdir size-run-same-${now}-2
#mv *size*.out ./size-run-same-${now}-2/ 2> /dev/null
#cd ${LOCATION}
#
#echo "CMD - Sending Notification E-Mail."
#mailx -s "Size Tests Same 2/3 Done" "migmig095@gmail.com" < email.msg
#
#${LOCATION}/${SCRIPT} -s --topic-same
#cd ${HOME}
#mkdir size-run-same-${now}-3
#mv *size*.out ./size-run-same-${now}-3/ 2> /dev/null
#cd ${LOCATION}
#
#echo "CMD - Sending Notification E-Mail."
#mailx -s "Size Tests Same 3/3 Done" "migmig095@gmail.com" < email.msg

# Run 3 times Size Scenario
${LOCATION}/${SCRIPT} -s
cd ${HOME}
mkdir size-run-${now}-1
mv *size*.out ./size-run-${now}-1/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests 1/3 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s
cd ${HOME}
mkdir size-run-${now}-2
mv *size*.out ./size-run-${now}-2/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests 2/3 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s
cd ${HOME}
mkdir size-run-${now}-3
mv *size*.out ./size-run-${now}-3/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests 3/3 Done" "migmig095@gmail.com" < email.msg
