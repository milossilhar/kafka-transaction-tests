#!/bin/bash

LOCATION="${HOME}/dp/kafka-transaction-tests"
SCRIPT="run-tests.sh"

now=$(date +"%Y-%m-%d-%H-%M")

# Run 5 times Producer Scenario with Same Topic Replication
${LOCATION}/${SCRIPT} -p --topic-same
cd ${HOME}
mkdir producer-run-same-${now}-1
mv *producer*.out ./producer-run-same-${now}-1/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests Same 1/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -p --topic-same
cd ${HOME}
mkdir producer-run-same-${now}-2
mv *producer*.out ./producer-run-same-${now}-2/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests Same 2/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -p --topic-same
cd ${HOME}
mkdir producer-run-same-${now}-3
mv *producer*.out ./producer-run-same-${now}-3/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests Same 3/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -p --topic-same
cd ${HOME}
mkdir producer-run-same-${now}-4
mv *producer*.out ./producer-run-same-${now}-4/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests Same 4/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -p --topic-same
cd ${HOME}
mkdir producer-run-same-${now}-5
mv *producer*.out ./producer-run-same-${now}-5/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests Same Done" "migmig095@gmail.com" < email.msg

# Run 5 times Producer Scenario
${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-1
mv *producer*.out ./producer-run-${now}-1/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests 1/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-2
mv *producer*.out ./producer-run-${now}-2/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests 2/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-3
mv *producer*.out ./producer-run-${now}-3/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests 3/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-4
mv *producer*.out ./producer-run-${now}-4/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests 4/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-5
mv *producer*.out ./producer-run-${now}-5/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Producer Tests are Done" "migmig095@gmail.com" < email.msg
