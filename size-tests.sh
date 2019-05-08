#!/bin/bash

LOCATION="${HOME}/dp/kafka-transaction-tests"
SCRIPT="run-tests.sh"

now=$(date +"%Y-%m-%d-%H-%M")

# Run 5 times Producer Scenario with Same Topic Replication
${LOCATION}/${SCRIPT} -s --topic-same
cd ${HOME}
mkdir size-run-same-${now}-1
mv *size*.out ./size-run-same-${now}-1/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests Same 1/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s --topic-same
cd ${HOME}
mkdir size-run-same-${now}-2
mv *size*.out ./size-run-same-${now}-2/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests Same 2/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s --topic-same
cd ${HOME}
mkdir size-run-same-${now}-3
mv *size*.out ./size-run-same-${now}-3/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests Same 3/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s --topic-same
cd ${HOME}
mkdir size-run-same-${now}-4
mv *size*.out ./size-run-same-${now}-4/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests Same 4/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s --topic-same
cd ${HOME}
mkdir size-run-same-${now}-5
mv *size*.out ./size-run-same-${now}-5/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests Same Done" "migmig095@gmail.com" < email.msg

# Run 5 times Producer Scenario
${LOCATION}/${SCRIPT} -s
cd ${HOME}
mkdir size-run-${now}-1
mv *size*.out ./size-run-${now}-1/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests 1/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s
cd ${HOME}
mkdir size-run-${now}-2
mv *size*.out ./size-run-${now}-2/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests 2/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s
cd ${HOME}
mkdir size-run-${now}-3
mv *size*.out ./size-run-${now}-3/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests 3/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s
cd ${HOME}
mkdir size-run-${now}-4
mv *size*.out ./size-run-${now}-4/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests 4/5 Done" "migmig095@gmail.com" < email.msg

${LOCATION}/${SCRIPT} -s
cd ${HOME}
mkdir size-run-${now}-5
mv *size*.out ./size-run-${now}-5/ 2> /dev/null
cd ${LOCATION}

echo "CMD - Sending Notification E-Mail."
mailx -s "Size Tests are Done" "migmig095@gmail.com" < email.msg
