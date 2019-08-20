#!/usr/bin/env bash

# Note: requires bash 4.2 or later

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
APPLICATION_NAME=ansible-tower
OPENSHIFT_PROJECT=demo-${APPLICATION_NAME}
: ${OPENSHIFT_USER_REFERENCE?} && OPENSHIFT_USER=

echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_PROJECT?}
echo "OK"

echo "Ansible Tower Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_PROJECT                    = ${OPENSHIFT_PROJECT}"
echo "_____________________________________________________________________"

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd ../config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

#TODO: attempt to automate download from https://developers.redhat.com/download-manager/file/codeready-workspaces-1.1.0.GA-operator-installer.tar.gz ...may require authentication
# something like: wget --user=mepley-se-jboss --password='password'  ${APPLICATION_ANSIBLE_TOWER_DOWNLOAD_URL}
# or wget ${APPLICATION_ANSIBLE_TOWER_DOWNLOAD_URL}

[[ -f ${APPLICATION_CODE_READY_WORKSPACES_LOCAL_INSTALLER} ]] || { echo "FAILED: could not find installer...you may need to download this from ${APPLICATION_ANSIBLE_TOWER_DOWNLOAD_URL}" && exit 1 ; } 

tar xvf ${APPLICATION_ANSIBLE_TOWER_DISTRIBUTION_PACKAGE_LATEST_NAME}

# install required database (postgres)
oc new-app postgresql-persistent

sleep 2s;

eval $(oc get secret/postgresql -o json | jq -r '.data | "NAME=" + ."database-name", "PASSWORD=" + ."database-password", "USER=" + ."database-user" | "export POSTGRESQL_" + . ')

# verify we have extracted the correct configuration information
: ${POSTGRESQL_NAME?}
: ${POSTGRESQL_USER?}
: ${POSTGRESQL_PASSWORD?}

# required template parameters
openshift_host
openshift_project
openshift_user
openshift_password
admin_password
secret_key
pg_username
pg_password
rabbitmq_password
rabbitmq_erlang_cookie





pushd ${APPLICATION_ANSIBLE_TOWER_LOCAL_INSTALLER_DIR}

echo 'redhat1!' | ./setup_openshift.sh -e openshift_password=$OPENSHIFT_PASSWORD -- -v

popd


echo "Done."
