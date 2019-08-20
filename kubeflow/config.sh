#!/usr/bin/env bash

ISTIO_VERSION=0.6.0
# TODO: ISTIO 1.0.0 requires helm to install -- need to rework installation process
# ISTIO_VERSION=1.0.0
ISTIO_HOME=./istio-${ISTIO_VERSION}

ISTIO_OSEXT_OPTIONS=(oxs linux)
ISTIO_OSEXT=${ISTIO_OSEXT_OPTIONS[1]}

KUBEFLOW_VERSION=latest
APPLICATION_KUBEFLOW_GITHUB_REPO=kubeflow/kubeflow
APPLICATION_KUBEFLOW_GITHUB_RELEASES_URL=https://github.com/${APPLICATION_KUBEFLOW_GITHUB_REPO}/releases/latest
