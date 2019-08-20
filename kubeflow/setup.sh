#!/usr/bin/env bash

# Configuration
pushd ..
. ./config-demo-geoint-2019.sh || { echo "FAILED: Could not configure" && exit 1 ; }
popd

# Additional Configuration
. ./config.sh

[[ -v OPENSHIFT_USER_ADMIN_AUTH_TOKEN ]] || { echo "FAILED: you must have a user with clusteradmin privileges" && exit 1 ; }
# oc whoami -c | grep admin | grep  ${OPENSHIFT_MASTER//\./-} || { echo "FAILED: you must be logged in as a user with clusteradmin privileges" && exit 1 ; }

#curl -kL https://git.io/getLatestIstio | sed 's/curl/curl -k /g' | ISTIO_VERSION=${ISTIO_VERSION} sh -
#export PATH="$PATH:${ISTIO_HOME}/bin"
#cd ${ISTIO_HOME}

if [ "x${ISTIO_VERSION}" = "x" ] ; then
  ISTIO_VERSION=$(curl -k  -L -s https://api.github.com/repos/istio/istio/releases/latest | grep tag_name | sed "s/ *\"tag_name\": *\"\(.*\)\",*/\1/")
fi

NAME="istio-$ISTIO_VERSION"
URL="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-${ISTIO_OSEXT}.tar.gz"
echo "Downloading $NAME from $URL ..."
curl -k  -L "$URL" | tar xz



##### wget https://github.com/kubeflow/kubeflow/releases/latest



