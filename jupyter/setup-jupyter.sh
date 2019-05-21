#!/bin/bash

PROJECT=oshinko
SPARK_CLUSTER_NAME="spy3"

# Switch to the project
oc project "${PROJECT}"

# Pull template resources from RAD
oc create -f https://radanalytics.io/resources.yaml

# Create the Oshinko environment
oc new-app --template oshinko-python36-spark-build-dc   -p APPLICATION_NAME=sparkpi   -p GIT_URI=https://github.com/elmiko/tutorial-sparkpi-python-flask.git   -p GIT_REF=python3   -p OSHINKO_CLUSTER_NAME="${SPARK_CLUSTER_NAME}"

# Need this one
oc expose svc/sparkpi
# I don't think we need this one
oc expose svc/sparkpi-headless

# Now we have to make the cluster
# This tool comes from RAD here:https://github.com/radanalyticsio/oshinko-cli/releases/download/v0.5.6/oshinko_v0.5.6_linux_amd64.tar.gz
./oshinko create spy3 --image=elmiko/openshift-spark:python36-latest --masters=1 --workers=3

# This app is based on the elmiko container below, he's a Red Hatter
# I created my own and added more libraries to it
# There is a way to add python libs to a notebook while it is running
# !conda install --yes --prefix /opt/conda numpy
#elmiko/jupyter-notebook-py36
oc new-app 'quay.io/danclark/jupyter-notebook-py36:latest' -e JUPYTER_NOTEBOOK_PASSWORD=${JUPYTER_PASSWORD}  -e PYSPARK_PYTHON=/opt/rh/rh-python36/root/usr/bin/python

oc expose svc/jupyter-notebook-py3

echo "Done."
