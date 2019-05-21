#!/usr/bin/env bash

echo "Create SKYDIVE demo"


oc project ${OPENSHIFT_PROJECT} oc new-project $OPENSHIFT_PROJECT || { echo "FAILED: could not find or create the necessary project" && echo "exit 1" ; }

oc create -f https://raw.githubusercontent.com/skydive-project/skydive/master/contrib/kubernetes/skydive.yaml

echo "Done."