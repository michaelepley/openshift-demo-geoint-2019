#!/usr/bin/env bash

# Note: requires bash 4.2 or later
# See also https://github.com/skydive-project/skydive/tree/master/contrib/openshift

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
APPLICATION_NAME=skydive
OPENSHIFT_PROJECT=demo-skydive
APPLICATION_SKYDIVE_LOCAL_INSTALLER=DOESNOTEXIST
APPLICATION_SKYDIVE_STREAMS_LOCAL_INSTALLER_DIR=DOESNOTEXIST


echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT?}
: ${APPLICATION_NAME?}
echo "OK"

echo "Skydive Configuration________________________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT                    = ${OPENSHIFT_PROJECT}"
echo "	APPLICATION_NAME                     = ${APPLICATION_NAME}"
echo "_____________________________________________________________________"

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd ../config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1


echo "Create SKYDIVE demo"

# analyzer and agent run as privileged container
oc adm policy add-scc-to-user privileged -z default
# analyzer need cluster-reader access get all informations from the cluster
oc adm policy add-cluster-role-to-user cluster-reader -z default

# oc create -f https://raw.githubusercontent.com/skydive-project/skydive/master/contrib/kubernetes/skydive.yaml
#
VERSION=master
oc process -f https://raw.githubusercontent.com/skydive-project/skydive/${VERSION}/contrib/openshift/skydive-template.yaml | oc apply -f -

oc expose svc/skydive-analyzer

echo "Done."