#!/usr/bin/env bash

# Note: requires bash 4.2 or later
# See also https://www.omnisci.com/docs/latest/

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
APPLICATION_NAME=omnisci
OPENSHIFT_OMNISCI_PROJECT=demo-omnisci
OPENSHIFT_PROJECT=${OPENSHIFT_OMNISCI_PROJECT}

echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT?}
: ${APPLICATION_NAME?}
echo "OK"

echo "Omnisci Configuration____________________________________________"
echo "	OPENSHIFT_USER_REFERENCE                     = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT                            = ${OPENSHIFT_PROJECT}"
echo "	APPLICATION_NAME                             = ${APPLICATION_NAME}"
echo "_____________________________________________________________________"


echo "--> checking prerequisites"
command yq >/dev/null || { echo "FAILED: missing prerequisite command yq" && exit 1 ; }


echo "	--> Create a new onmisci server configuration: to be mounted in a file omnisci.confg"

APPLICATION_OMNISCI_CONFIGURATION_FILE=$(cat <<'EOF_APPLICATION_OMNISCI_CONFIGURATION_FILE'
port=6274
calcite-port=6279
data="/omnisci-storage/data"
read-only=false
verbose=false
[web]
port=6273
frontend='frontend'
EOF_APPLICATION_OMNISCI_CONFIGURATION_FILE
)


oc get cm/omnisci-config -n ${OPENSHIFT_OMNISCI_PROJECT} || oc create configmap omnisci-config -n ${OPENSHIFT_OMNISCI_PROJECT} --from-literal=omnisci.conf="${APPLICATION_OMNISCI_CONFIGURATION_FILE}"







oc new-build --name=mapd-connector-build --code=https://github.com/omnisci/mapd-connector
oc new-app   --name=mapd-connector --code=https://github.com/omnisci/mapd-connector

oc new-app   --name=mapd-charting  --code=https://github.com/omnisci/mapd-charting

echo "Done."

