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
OPENSHIFT_PROJECTS_TO_CLEAN=(${OPENSHIFT_PROJECT}) 


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


echo "Clean SKYDIVE demo"


for OPENSHIFT_PROJECT_TO_CLEAN in ${OPENSHIFT_PROJECTS_TO_CLEAN[*]} ; do
	echo "	--> cleaning project ${OPENSHIFT_PROJECT_TO_CLEAN}"
	echo -n "		--> delete all openshift resources for application ${APPLICATION_NAME}..."
	oc delete all --all -n ${OPENSHIFT_PROJECT_TO_CLEAN}
	
	echo -n "	--> delete miscellaneous artifacts (including templates, but leave jenkins alone)..."
	OPENSHIFT_PROJECT_MISC_RESOURCES=(`oc get all,templates -n ${OPENSHIFT_PROJECT_TO_CLEAN} | grep -v '^NAME' | grep -v jenkins | awk '{ printf $1 " "; }' `)
	: ${OPENSHIFT_PROJECT_MISC_RESOURCES:-oc delete ${OPENSHIFT_PROJECT_MISC_RESOURCES} -n ${OPENSHIFT_PROJECT_TO_CLEAN} }

	echo "		--> optionally delete the project ... delete the project with 'oc delete project ${OPENSHIFT_PROJECT_TO_CLEAN} '"
	
done

echo "	--> delete all local artifacts"

echo "	--> deleting all local resources"
echo "		--> NOTE: nothing to do"
[[ -n ${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL} && "x/" -ne "${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL}" ]] && rm -rf ${NAUTICALCHART_FORKED_APPLICATION_REPOSITORY_LOCAL}

echo "Done"
