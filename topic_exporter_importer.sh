#!/bin/bash

set -e
set -x

KAFKA_ROOT="/etc/kafka"
ZK_STRING=$(grep 'zookeeper\.connect=' ${KAFKA_ROOT}/server.properties|awk -F"=" '{print $NF}');

dump() {
OUTPUTFILE=$1
echo "dumping kafka topics metadata into ${OUTPUTFILE}"
KAFKA_TOPICS=$(kafka-topics --list --zookeeper ${ZK_STRING} ${KAFKA_ROOT}/server.properties|awk -F"=" '{print $NF}')
for n in ${KAFKA_TOPICS} ;do
        kafka-topics --topic ${n} --describe --zookeeper ${ZK_STRING}|grep PartitionCount > ${OUTPUTFILE} 2>&1
done
}


restore() {
INPUTFILE=$1
echo "restoring from ${INPUTFILE}"
while read n; do
         TOPIC_NAME=$(echo ${n}| awk -F":" '{print $2}' |awk '{print $1}')
         REPLICATION_FACTOR=$(echo ${n}| awk -F":" '{print $3}' |awk '{print $1}')
         PARTITIONS=$(echo ${n}| awk -F":" '{print $4}' |awk '{print $1}')
         kafka-topics --topic ${TOPIC_NAME} --create --zookeeper ${ZK_STRING} --replication-factor ${REPLICATION_FACTOR} --partitions ${PARTITIONS}
done < ${INPUTFILE}
}

help() {
cat << EOF
$0 -a [action] -f [filename]
EOF
}


while getopts "a:f:" flag ; do
        case $flag in
                a ) ACTION=${OPTARG};;
                f ) FILE=${OPTARG};;
        esac
done

if [[ -z ${ACTION} ]] || [[ -z ${FILE} ]] ;then
        echo "missing action (-a) or filename (-f)"
        exit 1
fi

if [[ ${ACTION} == "restore" ]]; then
        restore ${FILE}
elif [[ ${ACTION} == "dump" ]]; then
        dump ${FILE}
else
        help
fi
