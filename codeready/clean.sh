#!/usr/bin/env bash

# Note: requires bash 4.2 or later
# See also https://github.com/skydive-project/skydive/tree/master/contrib/openshift

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
APPLICATION_NAME=code-ready-workspaces
OPENSHIFT_PROJECT=workspaces
APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER=codeready-workspaces-1.1.0.GA-operator-installer.tar.gz
APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR=code-ready-workspaces-operator-installer

OPENSHIFT_PROJECTS_TO_CLEAN=(${OPENSHIFT_PROJECT}) 


echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT?}
: ${APPLICATION_NAME?}
: ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER?}
: ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR?}
echo "OK"

echo "AMQ Streams Configuration____________________________________________"
echo "	OPENSHIFT_USER_REFERENCE                     = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT                            = ${OPENSHIFT_PROJECT}"
echo "	APPLICATION_NAME                             = ${APPLICATION_NAME}"
echo "	APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER      = ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER}"
echo "	APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR  = ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR}"
echo "_____________________________________________________________________"

echo "Clean AMQ Streams demo"

for OPENSHIFT_PROJECT_TO_CLEAN in ${OPENSHIFT_PROJECTS_TO_CLEAN[*]} ; do
	echo "	--> cleaning project ${OPENSHIFT_PROJECT_TO_CLEAN}"
	echo -n "		--> delete all openshift resources for application ${APPLICATION_NAME}..."
	oc delete all --all -n ${OPENSHIFT_PROJECT_TO_CLEAN}
	
	echo -n "	--> delete miscellaneous artifacts (including templates, but leave jenkins alone)..."
	OPENSHIFT_PROJECT_MISC_RESOURCES=(`oc get all,templates -n ${OPENSHIFT_PROJECT_TO_CLEAN} | grep -v '^NAME' | grep -v jenkins | awk '{ printf $1 " "; }' `)
	: ${OPENSHIFT_PROJECT_MISC_RESOURCES:-oc delete ${OPENSHIFT_PROJECT_MISC_RESOURCES} -n ${OPENSHIFT_PROJECT_TO_CLEAN} }

	echo "		--> optionally delete the project ... delete the project with 'oc delete project ${OPENSHIFT_PROJECT_TO_CLEAN} '"
	
done

## SANITY CHECK
realpath ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR} | grep "^/home/.*/git" || { echo "FAILED: REFUSING TO DELETE UNSAFE LOCATIONS" && exit 1 ; } 

echo "	--> delete all local artifacts"

echo "	--> deleting all local resources"
echo "		--> NOTE: nothing to do"
[[ -n ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR} ]] && [ "/" != "${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR}" ] && rm -rf ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR}

echo "Done."


