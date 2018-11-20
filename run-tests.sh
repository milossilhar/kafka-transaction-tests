#!/bin/bash

now=$(date +"%Y-%m-%d-%H-%M")

gps_size="50"
gps_name="gps"
im_size="100"
im_name="im"
store_size="80"
store_name="store"

# number of repeats
repeats="10000"
# properties file
property_file="producer.properties"

# mvn clean install

cd kafka-tests-producer

# 10 000 transactions 1 gps
mvn exec:java -Dexec.args="-p ${property_file}  -n ${repeats} -m ${gps_name},1,${gps_size}" | tee ~/producer-result-1-0-0_${now}

# 10 000 transactions 2 gps, 1 store
mvn exec:java -Dexec.args="-p ${property_file}  -n ${repeats} -m ${gps_name},2,${gps_size} ${store_name},1,${store_size}" | tee ~/producer-result-2-0-1_${now}

# 10 000 transactions 5 gps, 1 im, 2 store
mvn exec:java -Dexec.args="-p ${property_file}  -n ${repeats} -m ${gps_name},5,${gps_size} ${im_name},1,${im_size} ${store_name},2,${store_size}" | tee ~/producer-result-5-1-2_${now}

# 10 000 transactions 10 gps, 2 im, 4 store
mvn exec:java -Dexec.args="-p ${property_file}  -n ${repeats} -m ${gps_name},10,${gps_size} ${im_name},2,${im_size} ${store_name},4,${store_size}" | tee ~/producer-result-10-2-4_${now}

# 10 000 transactions 50 gps, 10 im, 20 store
mvn exec:java -Dexec.args="-p ${property_file}  -n ${repeats} -m ${gps_name},50,${gps_size} ${im_name},10,${im_size} ${store_name},20,${store_size}" | tee ~/producer-result-50-10-20_${now}

