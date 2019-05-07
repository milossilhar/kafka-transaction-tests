#!/bin/bash
set -e

LOCATION="${HOME}/Documents/diplomka-git/kafka-transaction-tests"
SCRIPT="run-tests-alter.sh"

now=$(date +"%Y-%m-%d-%H-%M")

# Run 5 times Producer Scenario
${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-1
if [ -e *producer*.out ]; then
  cp *producer*.out ./producer-run-${now}-1/
fi
cd ${LOCATION}

${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-2
if [ -e *producer*.out ]; then
  cp *producer*.out ./producer-run-${now}-2/
fi
cd ${LOCATION}

${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-3
if [ -e *producer*.out ]; then
  cp *producer*.out ./producer-run-${now}-3/
fi
cd ${LOCATION}

${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-4
if [ -e *producer*.out ]; then
  cp *producer*.out ./producer-run-${now}-4/
fi
cd ${LOCATION}

${LOCATION}/${SCRIPT} -p
cd ${HOME}
mkdir producer-run-${now}-5
if [ -e *producer*.out ]; then
  cp *producer*.out ./producer-run-${now}-5/
fi
cd ${LOCATION}

mailx -s "Producer Tests are Done" "migmig095@gmail.com" < email.msg
