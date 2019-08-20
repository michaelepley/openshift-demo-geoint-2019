#see https://github.com/jupyter/jupyter_server/tree/master/jupyter_server

oc get dc || echo "FAILED: could not verify connection to Openshift"

oc new-build --image-stream=openshift/python --code='https://github.com/jupyter/jupyter_server.git' --context-dir='jupyter_server'