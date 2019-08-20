#!/usr/bin/env bash

# Note: requires bash 4.2 or later
# See also https://github.com/skydive-project/skydive/tree/master/contrib/openshift

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
APPLICATION_NAME=amq-streams
OPENSHIFT_PROJECT=demo-amq-streams
APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER=amq-streams-1.1.0-ocp-install-examples.zip
APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER_DIR=amq-streams-installer

APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_NAME=demo-cluster
APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_TEST_TOPIC_NAME=test-topic

echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT?}
: ${APPLICATION_NAME?}
: ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER?}
: ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER_DIR?}
echo "OK"

echo "AMQ Streams Configuration____________________________________________"
echo "	OPENSHIFT_USER_REFERENCE                     = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT                            = ${OPENSHIFT_PROJECT}"
echo "	APPLICATION_NAME                             = ${APPLICATION_NAME}"
echo "	APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER      = ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER}"
echo "	APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER_DIR  = ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER_DIR}"
echo "_____________________________________________________________________"


echo "--> checking prerequisites"
command yq >/dev/null || { echo "FAILED: missing prerequisite command yq" && exit 1 ; }

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd ../config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1


echo "Create AMQ Streams demo"

echo "--> Installing AMQ streams"
echo "	--> getting AMQ streams installer"
[[ -f ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER} ]] || { echo "FAILED: could not find installer...you may need to download this from https://access.redhat.com/jbossnetwork/restricted/softwareDownload.html?softwareId=66571" && exit 1 ; } 
unzip ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER} -d ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER_DIR}

pushd ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER_DIR}

echo "	--> customizing AMQ streams installer to operate in ${OPENSHIFT_PROJECT} project"
sed -i.bak 's/namespace: .*/namespace: '${OPENSHIFT_PROJECT}'/' install/cluster-operator/*RoleBinding*.yaml

echo "	--> creating AMQ streams operators"
oc apply -f install/cluster-operator -n ${OPENSHIFT_PROJECT}
oc apply -f examples/templates/cluster-operator -n ${OPENSHIFT_PROJECT}

echo -n "	--> creating AMQ streams roles: "
echo -n "administrator "
oc apply -f install/strimzi-admin
echo ""

echo "	--> waiting for the cluster operators to be ready....press any key to proceed"
while ! oc get pods | grep strimzi-cluster-operator | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

popd


echo "--> creating default AMQ streams Kafka demo cluster"

mkdir -p resources

#use the existing examples as a base for modification for our cluster
cat ${APPLICATION_AMQ_STREAMS_LOCAL_INSTALLER_DIR}/examples/kafka/kafka-persistent.yaml | yq '.metadata.name = "'${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_NAME}'" | .spec.kafka.storage.size = "100M" | .spec.zookeeper.storage.size = "100M"' > resources/${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_NAME}.json

oc create -f resources/${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_NAME}.json

echo "	--> waiting for the entity and user operators to be ready....press any key to proceed"
while ! oc get pods | grep ${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_NAME}-operator | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

mkdir -p tmp
mkdir -p tmp/test
echo "	--> verify the Kafka cluster is operating as expected"
echo "		--> just echo back its configuration, and check that some expected paramters are present"
oc get Kafka/${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_NAME} -o json | jq '.spec.kafka.config' | tee tmp/kafka-cluster-status.json && { cat tmp/kafka-cluster-status.json | jq -e '."transaction.state.log.min.isr"' || { echo "FAILED: missing expected runtime parameter" && exit 1 ; } ; } &&  { cat tmp/kafka-cluster-status.json | jq -e '."offsets.topic.replication.factor"' || { echo "FAILED: missing expected runtime parameter" && exit 1 ; } ; } 
echo "		--> pump some messages through a producer and get these back out a consumer, via a test topic"
# first, import client images into openshift so we can use these ... registry.access.redhat.com/amq7/amq-streams-kafka:1.1.0-kafka-2.1.1
oc import-image openshift/amq-streams-kafka:1.1.0 -n openshift --from=registry.access.redhat.com/amq7/amq-streams-kafka:1.1.0-kafka-2.1.1 --confirm
oc tag openshift/amq-streams-kafka:1.1.0 openshift/amq-streams-kafka:latest -n openshift
# first, start the consumer
oc run kafka-consumer -ti --image=docker-registry.default.svc:5000/openshift/amq-streams-kafka:latest --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server ${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_NAME}-kafka-bootstrap:9092 --topic ${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_TEST_TOPIC_NAME} --from-beginning > tmp/test/received-messages.txt &
CONSUMER_PID=$!
# then send some message 
oc run kafka-producer -ti --image=docker-registry.default.svc:5000/openshift/amq-streams-kafka:latest --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list ${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_NAME}-kafka-bootstrap:9092 --topic ${APPLICATION_AMQ_STREAMS_KAFKA_CLUSTER_DEMO_TEST_TOPIC_NAME} --request-timeout-ms 1000 




echo "	--> adding some default topics"



echo "Done."
