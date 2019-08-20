#!/usr/bin/env bash

# Note: requires bash 4.2 or later

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
APPLICATION_NAME=code-ready-workspaces
OPENSHIFT_PROJECT=workspaces
APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER=codeready-workspaces-1.1.0.GA-operator-installer.tar.gz
APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR=codeready-workspaces-operator-installer

echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT?}
echo "OK"

echo "CodeReady Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT                    = ${OPENSHIFT_PROJECT}"
echo "_____________________________________________________________________"

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd ../config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

#TODO: attempt to automate download from https://developers.redhat.com/download-manager/file/codeready-workspaces-1.1.0.GA-operator-installer.tar.gz ...may require authentication
# something like: wget --user=mepley-se-jboss --password='password'  https://developers.redhat.com/download-manager/file/codeready-workspaces-1.1.0.GA-operator-installer.tar.gz

[[ -f ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER} ]] || { echo "FAILED: could not find installer...you may need to download this from https://developers.redhat.com/download-manager/file/codeready-workspaces-1.1.0.GA-operator-installer.tar.gz" && exit 1 ; } 
tar xvf ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER}

pushd ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER_DIR}

./deploy.sh --deploy --public-certs

popd

echo "Done."

