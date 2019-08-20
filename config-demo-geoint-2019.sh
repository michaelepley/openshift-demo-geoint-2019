#!/usr/bin/env bash

# Note: requires bash 4.2 or later

# assume the demo is interactive
: ${DEMO_INTERACTIVE:=true}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS:=30}

#                                0     1        2        3          4      5            6               7                  8                   9         10        11 
DEMO_TARGET_OPENSHIFT_INSTANCES=(local rhsademo rhtps-io fortnebula itpaas nsabine-vrtx dan-redhatgovio mepley-demo-redhatgovio geoint-redhatgovio  hattrick1 hattrick2 hattrick3)
# Target GEOINT-REHATGOVIO
#DEMO_TARGET_OPENSHIFT_INSTANCE=${DEMO_TARGET_OPENSHIFT_INSTANCES[8]}
# Target MEPLEY-DEMO-REHATGOVIO
DEMO_TARGET_OPENSHIFT_INSTANCE=${DEMO_TARGET_OPENSHIFT_INSTANCES[7]}

# assume we don't need to expressly verify the clusters operational status
: ${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS:=false}

# Configuration
pushd config >/dev/null 2>&1
. ./config.sh || { echo "FAILED: Could not configure generic demo environment" && exit 1 ; }
# we will be using github for this demo, so load these configuration resources 
. ./config-resources-github.sh || { echo "FAILED: Could not configure github demo resources" && exit 1 ; }
popd >/dev/null 2>&1

[[ -v CONFIGURATION_DEMO_GEOINT_REDHATGOVIO_COMPLETED ]] && echo "Using openshift demo setup test configuration" && { return || exit ; }
: ${CONFIGURATION_DEMO_OPENSHIFT_SIMPLE_DISPLAY:=$CONFIGURATION_DISPLAY}
# uncomment to force these scripts to display configuration information
CONFIGURATION_OPENSHIFT_DEMO_DISPLAY=true

# Demo specific configuration items
# modify the user, or copy to new reference, then modify
#OPENSHIFT_USER_PROJECT_REF="OPENSHIFT_USER_GEOINT_REDHATGOVIO_ADMIN[3]" && eval "${OPENSHIFT_USER_PROJECT_REF}=mepley-test-setup"
: ${OPENSHIFT_PROJECT_TEST_SETUP_DEFAULT:=${OPENSHIFT_USER_GEOINT_REDHATGOVIO_ADMIN[0]}-test-setup}
OPENSHIFT_PROJECT_TEST_SETUP=${OPENSHIFT_PROJECT_TEST_SETUP_DEFAULT}

#OPENSHIFT_USER_REFERENCE_PRIMARY_DEFAULT
# Set the base configuration variables for the openshift-demo-simple
: ${OPENSHIFT_DOMAIN:=$OPENSHIFT_DOMAIN_DEFAULT}
: ${OPENSHIFT_MASTER:=$OPENSHIFT_MASTER_PRIMARY_DEFAULT}
: ${OPENSHIFT_APPS:=$OPENSHIFT_APPS_PRIMARY_DEFAULT}
: ${OPENSHIFT_PROXY_AUTH:=$OPENSHIFT_PROXY_AUTH_PRIMARY_DEFAULT}
OPENSHIFT_USER_REFERENCE=${OPENSHIFT_USER_REFERENCE_PRIMARY_DEFAULT}
: ${OPENSHIFT_USER:=$OPENSHIFT_USER_PRIMARY_DEFAULT}
: ${OPENSHIFT_USER_PASSWORD:=$OPENSHIFT_USER_PRIMARY_PASSWORD_DEFAULT}
: ${OPENSHIFT_AUTH_METHOD:=$OPENSHIFT_AUTH_METHOD_PRIMARY_DEFAULT}
OPENSHIFT_PROJECT=${OPENSHIFT_PROJECT_TEST_SETUP}
: ${OPENSHIFT_OUTPUT_FORMAT:=$OPENSHIFT_OUTPUT_FORMAT_DEFAULT}

if [ "$CONFIGURATION_OPENSHIFT_SETUP_TEST_DISPLAY" != "false" ]; then
	echo "Demo Openshift Simple Configuration_________________________"
	echo "	OPENSHIFT_USER_REFERENCE_PRIMARY_DEFAULT = ${OPENSHIFT_USER_REFERENCE_PRIMARY_DEFAULT}"
	echo "	OPENSHIFT_USER_GEOINT_REDHATGOVIO_ADMIN           = ${OPENSHIFT_USER_GEOINT_REDHATGOVIO_ADMIN[@]}"
	echo "	OPENSHIFT_PROJECT_TEST_SETUP_DEFAULT     = ${OPENSHIFT_PROJECT_TEST_SETUP_DEFAULT}"
	echo "	OPENSHIFT_PROJECT_TEST_SETUP             = ${OPENSHIFT_PROJECT_TEST_SETUP}"
	echo "	OPENSHIFT_DOMAIN                         = ${OPENSHIFT_DOMAIN}"
	echo "	OPENSHIFT_MASTER                         = ${OPENSHIFT_MASTER_PRIMARY_DEFAULT}"
	echo "	OPENSHIFT_APPS                           = ${OPENSHIFT_APPS}"
	echo "	OPENSHIFT_PROXY_AUTH                     = ${OPENSHIFT_PROXY_AUTH}"
	echo "	OPENSHIFT_USER_REFERENCE                 = ${OPENSHIFT_USER_REFERENCE}"
	echo "	OPENSHIFT_USER                           = ${OPENSHIFT_USER}"
	echo "	OPENSHIFT_USER_PASSWORD                  = `echo ${OPENSHIFT_USER_PASSWORD} | md5sum` (obfuscated)"
	echo "	OPENSHIFT_AUTH_METHOD                    = ${OPENSHIFT_AUTH_METHOD}"
	echo "	OPENSHIFT_PROJECT                        = ${OPENSHIFT_PROJECT}"
	echo "	OPENSHIFT_OUTPUT_FORMAT                  = ${OPENSHIFT_OUTPUT_FORMAT}"
	echo "____________________________________________________________"
fi

CONFIGURATION_DEMO_GEOINT_REDHATGOVIO_COMPLETED=true


