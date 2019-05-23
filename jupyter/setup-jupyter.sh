#!/usr/bin/env bash

# Note: requires bash 4.2 or later

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
OPENSHIFT_PROJECT=demo-jupyter
SPARK_CLUSTER_NAME=mysparkcluster


echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT?}
: ${SPARK_CLUSTER_NAME?}
echo "OK"

echo "Jupyter / Spark Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT                    = ${OPENSHIFT_PROJECT}"
echo "_____________________________________________________________________"

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd ../config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

# Pull template resources from RAD
oc create -f https://radanalytics.io/resources.yaml

oc new-app --template oshinko-webui
#oc new-app --template oshinko-rest -p OSHINKO_CLUSTER_NAMESPACE=demo-jupyter

echo "	--> Waiting for Oshinko Web UI  application to start....press any key to proceed"
while ! oc get pods | grep oshinko-web | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

# it looks like oshinko provides a jenkinsfile build for the REST CLI
oc new-build https://github.com/radanalyticsio/oshinko-cli

## Use the REST API to define a couple of different clusters, see https://github.com/radanalyticsio/oshinko-cli/blob/master/rest/docs/ClusterConfigs.md
echo "	--> Create a new oshinko cluster configuration: basic"
oc get cm/basic-oshinko-cluster-config  || oc create configmap basic-oshinko-cluster-config \
--from-literal=mastercount=1 \
--from-literal=workercount=3 \
--from-literal=sparkmasterconfig="" \
--from-literal=sparkworkerconfig="" \
--from-literal=sparkimage="elmiko/openshift-spark:python36-latest"
echo "	--> Create a new oshinko cluster configuration: pi-demo"
oc get cm/pi-demo-oshinko-cluster-config  || oc create configmap pi-demo-oshinko-cluster-config \
--from-literal=mastercount=1 \
--from-literal=workercount=3 \
--from-literal=sparkmasterconfig="" \
--from-literal=sparkworkerconfig="" \
--from-literal=sparkimage="elmiko/openshift-spark:python36-latest"

echo "	--> getting route to Oshinko REST API endpoint"
APPLICATION_OSHINKO_REST_ENDPOINT=`oc get route/oshinko-rest -o jsonpath='{.spec.host}'`


echo "	--> request oshinko use the new cluster configuration by name"
curl -H "Content-Type: application/json" -X POST -d '{"name": "basic", "config": {"name": "basic-oshinko-cluster-config"}}' http://${APPLICATION_OSHINKO_REST_ENDPOINT}/clusters
curl -H "Content-Type: application/json" -X POST -d '{"name": "pi-demo", "config": {"name": "pi-demo-oshinko-cluster-config"}}' http://${APPLICATION_OSHINKO_REST_ENDPOINT}/clusters
echo "	--> Verify the new clusters have been created"

for OSHINKO_CLUSTER_EXPECTED in basic pi-demo ; do curl -s http://oshinko-rest-demo-jupyter.apps.mepley-demo.redhatgov.io/clusters | jq '.clusters[] | select (.name=="'${OSHINKO_CLUSTER_EXPECTED}'")' && echo "		--> found oshinko managed spark cluster ${OSHINKO_CLUSTER_EXPECTED}" || { echo "FAILED: could not find expected cluster ${OSHINKO_CLUSTER_EXPECTED}" ; } ; done

# Create the spark environment
### no python3 ref:  oc new-app --template oshinko-python36-spark-build-dc   -p APPLICATION_NAME=sparkpi   -p GIT_URI=https://github.com/elmiko/tutorial-sparkpi-python-flask.git   -p GIT_REF=python3   -p OSHINKO_CLUSTER_NAME="${SPARK_CLUSTER_NAME}"
oc new-app --template oshinko-python36-spark-build-dc   -p APPLICATION_NAME=sparkpi   -p GIT_URI=https://github.com/elmiko/tutorial-sparkpi-python-flask.git  -p OSHINKO_CLUSTER_NAME="${SPARK_CLUSTER_NAME}"

# Need this one
oc expose svc/sparkpi
# I don't think we need this one
oc expose svc/sparkpi-headless

# Now we have to make the cluster
# This tool comes from RAD here:https://github.com/radanalyticsio/oshinko-cli/releases/download/v0.5.6/oshinko_v0.5.6_linux_amd64.tar.gz
# ./oshinko create spy3 --image=elmiko/openshift-spark:python36-latest --masters=1 --workers=3


# This app is based on the elmiko container below, he's a Red Hatter
# I created my own and added more libraries to it
# There is a way to add python libs to a notebook while it is running
# !conda install --yes --prefix /opt/conda numpy
#elmiko/jupyter-notebook-py36
oc new-app 'quay.io/danclark/jupyter-notebook-py36:latest' -e JUPYTER_NOTEBOOK_PASSWORD=${JUPYTER_PASSWORD}  -e PYSPARK_PYTHON=/opt/rh/rh-python36/root/usr/bin/python

oc expose svc/jupyter-notebook-py36

#TODO use Jypter's rest API and as custom S2I build to create a new deployment from a git repo containing the correct notebook

echo "Done."
