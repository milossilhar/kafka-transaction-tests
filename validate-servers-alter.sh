#!/bin/bash

function printUsage {
  echo "USAGE: $0"
  exit 1
}

if [ "$#" -ne "0" ]; then
  printUsage
fi

ZOO_SERVERS=( "nymfe26.fi.muni.cz" "nymfe27.fi.muni.cz" "nymfe28.fi.muni.cz" )
KAFKA_SERVERS=( "nymfe50.fi.muni.cz" "nymfe51.fi.muni.cz" "nymfe52.fi.muni.cz" "nymfe53.fi.muni.cz" "nymfe54.fi.muni.cz" "nymfe62.fi.muni.cz" "nymfe64.fi.muni.cz" "nymfe70.fi.muni.cz" "nymfe71.fi.muni.cz" )

for zoo in ${ZOO_SERVERS[@]}; do
  echo "CMD - ssh $zoo \"who -q\""
  ssh $zoo "who -q"
done
for kafka in ${KAFKA_SERVERS[@]}; do
  echo "CMD - ssh $kafka \"who -q; df -h /tmp/\""
  ssh $kafka "who -q; df -h /tmp/"
done

