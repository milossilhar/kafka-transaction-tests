#!/bin/bash

function printUsage {
  echo "USAGE: $0"
  exit 1
}

if [ "$#" -ne "0" ]; then
  printUsage
fi

ZOO_SERVERS=( "nymfe30.fi.muni.cz" "nymfe31.fi.muni.cz" "nymfe32.fi.muni.cz" )
KAFKA_SERVERS=( "nymfe40.fi.muni.cz" "nymfe41.fi.muni.cz" "nymfe42.fi.muni.cz" "nymfe43.fi.muni.cz" "nymfe44.fi.muni.cz" "nymfe45.fi.muni.cz" "nymfe46.fi.muni.cz" "nymfe47.fi.muni.cz" "nymfe48.fi.muni.cz" )

for zoo in ${ZOO_SERVERS[@]}; do
  echo "CMD - ssh $zoo \"who -q\""
  ssh $zoo "who -q"
done
for kafka in ${KAFKA_SERVERS[@]}; do
  echo "CMD - ssh $kafka \"who -q; df -h /tmp/\""
  ssh $kafka "who -q; df -h /tmp/"
done

