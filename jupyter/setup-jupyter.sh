#!/usr/bin/env bash

# Note: requires bash 4.2 or later

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
OPENSHIFT_PROJECT=demo-jupyter
OPENSHIFT_JUPYTER_PROJECT=demo-jupyter
OPENSHIFT_OSHINKO_PROJECT=oshinko
OPENSHIFT_SPARK_PROJECT=spark

APPLICATION_NAME_OSHINKO=oshinko
APPLICATION_NAME_SPARK=spark
APPLICATION_NAME_JUPYTER=jupyter-notebook

APPLICATION_SPARK_CLUSTER_NAME=mysparkcluster
APPLICATION_JUPYTER_PASSWORD=password1!


echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT?}
: ${OPENSHIFT_JUPYTER_PROJECT?}
: ${OPENSHIFT_OSHINKO_PROJECT?}
: ${APPLICATION_SPARK_CLUSTER_NAME?}
: ${APPLICATION_JUPYTER_PASSWORD?}
echo "OK"

echo "Jupyter / Spark Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT                    = ${OPENSHIFT_PROJECT}"
echo "	OPENSHIFT_JUPYTER_PROJECT            = ${OPENSHIFT_JUPYTER_PROJECT}"
echo "	OPENSHIFT_OSHINKO_PROJECT            = ${OPENSHIFT_OSHINKO_PROJECT}"
echo "	OPENSHIFT_SPARK_PROJECT              = ${OPENSHIFT_SPARK_PROJECT}"
echo ""
echo "	APPLICATION_SPARK_CLUSTER_NAME       = ${APPLICATION_SPARK_CLUSTER_NAME}
echo "	APPLICATION_JUPYTER_PASSWORD         = ${APPLICATION_JUPYTER_PASSWORD}
echo "_____________________________________________________________________"

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd ../config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_JUPYTER_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_OSHINKO_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_SPARK_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

mkdir -p resources

# Pull template resources from RAD
curl -s https://radanalytics.io/resources.yaml > resources/radanalytics-resources.yaml ||  || { echo "FAILED: Could not download the necessary resources" && exit 1; }
oc create -f resources/radanalytics-resources.yaml -n ${OPENSHIFT_OSHINKO_PROJECT}
#oc create -f oshinko-cli.yaml -n ${OPENSHIFT_OSHINKO_PROJECT}
oc create -f oshinko-rest.yaml -n ${OPENSHIFT_OSHINKO_PROJECT}

# it looks like oshinko provides a jenkinsfile build for the REST CLI -- but it does not seem to actually work
# oc new-build https://github.com/radanalyticsio/oshinko-cli -n ${OPENSHIFT_OSHINKO_PROJECT}
# so we will use a pre-built template
oc new-app --template oshinko-webui -n ${OPENSHIFT_OSHINKO_PROJECT}
#oc new-app --template oshinko-cli  -n ${OPENSHIFT_OSHINKO_PROJECT} -p OSHINKO_CLUSTER_NAMESPACE=${OPENSHIFT_OSHINKO_PROJECT} 
oc new-app --template oshinko-rest  -n ${OPENSHIFT_OSHINKO_PROJECT} -p OSHINKO_CLUSTER_NAMESPACE=${OPENSHIFT_OSHINKO_PROJECT} 

# grant the oshinko web gui and rest access to the spark namespace
#oc adm policy add-role-to-user view oshinko-rest:default -n spark
oc adm policy add-role-to-user edit system:serviceaccount:${OPENSHIFT_OSHINKO_PROJECT}:oshinko -n spark
oc adm policy add-role-to-user edit system:serviceaccount:${OPENSHIFT_OSHINKO_PROJECT}:default -n spark
#
echo "	--> Waiting for Oshinko Web UI  application to start....press any key to proceed"
while ! oc get pods -n ${OPENSHIFT_OSHINKO_PROJECT} | grep oshinko-web | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> Waiting for Oshinko REST API application to start....press any key to proceed"
while ! oc get pods -n ${OPENSHIFT_OSHINKO_PROJECT} | grep oshinko-rest | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""


echo "	--> getting route to Oshinko REST API endpoint"
APPLICATION_OSHINKO_REST_ENDPOINT=`oc get route/oshinko-rest -n ${OPENSHIFT_OSHINKO_PROJECT} -o jsonpath='{.spec.host}'`

## Use the REST API to define a couple of different clusters, see https://github.com/radanalyticsio/oshinko-cli/blob/master/rest/docs/ClusterConfigs.md
echo "	--> Create a new oshinko cluster configuration: basic"
oc get cm/basic-oshinko-cluster-config -n ${OPENSHIFT_OSHINKO_PROJECT}  || oc create configmap basic-oshinko-cluster-config -n ${OPENSHIFT_SPARK_PROJECT} \
--from-literal=mastercount=1 \
--from-literal=workercount=3 \
--from-literal=sparkmasterconfig="" \
--from-literal=sparkworkerconfig="" \
--from-literal=sparkimage="elmiko/openshift-spark:python36-latest"
echo "	--> Create a new oshinko cluster configuration: pi-demo"
oc get cm/pi-demo-oshinko-cluster-config -n ${OPENSHIFT_OSHINKO_PROJECT} || oc create configmap pi-demo-oshinko-cluster-config -n ${OPENSHIFT_OSHINKO_PROJECT} \
--from-literal=mastercount=1 \
--from-literal=workercount=3 \
--from-literal=sparkmasterconfig="" \
--from-literal=sparkworkerconfig="" \
--from-literal=sparkimage="elmiko/openshift-spark:python36-latest"

# there are a couple of default cluster definitions that are provided by the oshinko template
curl -H "Content-Type: application/json" -X POST -d '{"name": "default", "config": {"name": "default-oshinko-cluster-config"}}' http://${APPLICATION_OSHINKO_REST_ENDPOINT}/clusters


echo "	--> request oshinko use the new cluster configuration by name"
curl -H "Content-Type: application/json" -X POST -d '{"name": "basic", "config": {"name": "basic-oshinko-cluster-config"}}' http://${APPLICATION_OSHINKO_REST_ENDPOINT}/clusters
curl -H "Content-Type: application/json" -X POST -d '{"name": "pi-demo", "config": {"name": "pi-demo-oshinko-cluster-config"}}' http://${APPLICATION_OSHINKO_REST_ENDPOINT}/clusters
echo "	--> Verify the new clusters have been created"

for OSHINKO_CLUSTER_EXPECTED in basic pi-demo ; do curl -s http://${APPLICATION_OSHINKO_REST_ENDPOINT}/clusters | jq '.clusters[] | select (.name=="'${OSHINKO_CLUSTER_EXPECTED}'")' && echo "		--> found oshinko managed spark cluster ${OSHINKO_CLUSTER_EXPECTED}" || { echo "FAILED: could not find expected cluster ${OSHINKO_CLUSTER_EXPECTED}" ; } ; done



exit 
# Create the spark environment
### no python3 ref:  oc new-app --template oshinko-python36-spark-build-dc   -p APPLICATION_NAME=sparkpi   -p GIT_URI=https://github.com/elmiko/tutorial-sparkpi-python-flask.git   -p GIT_REF=python3   -p OSHINKO_CLUSTER_NAME="${APPLICATION_SPARK_CLUSTER_NAME}"

# first, copy the template into the spark namespace
mkdir -p resources && oc get template/oshinko-python36-spark-build-dc -n demo-jupyter -o json > resources/template-oshinko-python36-spark-build-dc.json
cat resources/template-oshinko-python36-spark-build-dc.json | jq '.metadata.namespace="spark"' > resources/template-oshinko-python36-spark-build-dc.spark.json
oc create -n spark -f resources/template-oshinko-python36-spark-build-dc.spark.json

oc new-app --name=sparkpi --template oshinko-python36-spark-build-dc -n ${OPENSHIFT_SPARK_PROJECT}  -p APPLICATION_NAME=sparkpi   -p GIT_URI=https://github.com/elmiko/tutorial-sparkpi-python-flask.git  -p OSHINKO_CLUSTER_NAME="${APPLICATION_SPARK_CLUSTER_NAME}"

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
oc new-app -n ${OPENSHIFT_JUPYTER_PROJECT} --name=${APPLICATION_NAME_JUPYTER} 'quay.io/danclark/jupyter-notebook-py36:latest' -e JUPYTER_NOTEBOOK_PASSWORD=${APPLICATION_JUPYTER_PASSWORD}  -e PYSPARK_PYTHON=/opt/rh/rh-python36/root/usr/bin/python
oc expose svc/${APPLICATION_NAME_JUPYTER}

echo "	--> Waiting for ${APPLICATION_NAME_JUPYTER} application to start....press any key to proceed"
while ! oc get pods -n ${OPENSHIFT_JUPYTER_PROJECT} | grep ${APPLICATION_NAME_JUPYTER} | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

# See https://jupyter-notebook.readthedocs.io/
#TODO use Jypter's rest API and a custom S2I build to create a new deployment from a git repo containing the correct notebook
# see https://github.com/jupyter/jupyter/wiki/Jupyter-Notebook-Server-API

echo "	--> getting the location of the Jupyter REST API endpoint"
APPLICATION_JUPYTER_REST_ENDPOINT=`oc get route/${APPLICATION_NAME_JUPYTER} -n ${OPENSHIFT_JUPYTER_PROJECT} -o jsonpath='{.spec.host}'`

curl https://${APPLICATION_JUPYTER_REST_ENDPOINT}/api || echo "FAILED: could not contact the Jupyter API"








curl -X PUT -H "_xsrf=2|a2707fbd|ef8c06c13d82178f8fe930ce5f0f6313|1559540499;" -H 'X-XSRFToken: 2|a2707fbd|ef8c06c13d82178f8fe930ce5f0f6313|1559540499' http://${APPLICATION_JUPYTER_REST_ENDPOINT}/api/contents/path/Name.ipynb?_=1559541490911
 
curl -X PUT -H 'Accept: application/json, text/javascript'\
     -H '_xsrf: 2|a2707fbd|ef8c06c13d82178f8fe930ce5f0f6313|1559540499;' \
     -H 'X-XSRFToken: 2|a2707fbd|ef8c06c13d82178f8fe930ce5f0f6313|1559540499' \
     -H 'Cookie: d7e8207e4eee8ed706316433055d1312=7034edcf57ef60646aa8f422685ef657; _xsrf=2|a2707fbd|ef8c06c13d82178f8fe930ce5f0f6313|1559540499; username-jupyter-notebook-py36-demo-jupyter-apps-mepley-demo-redhatgov-io="2|1:0|10:1559540503|73:username-jupyter-notebook-py36-demo-jupyter-apps-mepley-demo-redhatgov-io|44:MDAxMTc1NjhjZTk0NDY2MWE2YjhhMTI1ZjgyMDExOGU=|4f6d69a50190ffdf240215945956787426efde8c49b98183a1c75166113c80c3'  \
      http://${APPLICATION_JUPYTER_REST_ENDPOINT}/api/contents/path/Name.ipynb?_=1559541490911
 
 
 curl 'http://jupyter-notebook-py36-demo-jupyter.apps.mepley-demo.redhatgov.io/api/sessions?_=1559541490911' \
   -H 'Cookie: d7e8207e4eee8ed706316433055d1312=7034edcf57ef60646aa8f422685ef657; _xsrf=2|a2707fbd|ef8c06c13d82178f8fe930ce5f0f6313|1559540499; username-jupyter-notebook-py36-demo-jupyter-apps-mepley-demo-redhatgov-io="2|1:0|10:1559540503|73:username-jupyter-notebook-py36-demo-jupyter-apps-mepley-demo-redhatgov-io|44:MDAxMTc1NjhjZTk0NDY2MWE2YjhhMTI1ZjgyMDExOGU=|4f6d69a50190ffdf240215945956787426efde8c49b98183a1c75166113c80c3"' \
   -H 'DNT: 1' -H 'Accept-Encoding: gzip, deflate'
   -H 'Accept-Language: en-US,en;q=0.9'
   -H 'User-Agent: Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36'
   -H 'Accept: application/json, text/javascript, */*; q=0.01' \
   -H 'Referer: http://jupyter-notebook-py36-demo-jupyter.apps.mepley-demo.redhatgov.io/tree' \
   -H 'X-Requested-With: XMLHttpRequest' \
   -H 'Connection: keep-alive' \
   -H 'X-XSRFToken: 2|a2707fbd|ef8c06c13d82178f8fe930ce5f0f6313|1559540499' --compressed
echo "Done."
