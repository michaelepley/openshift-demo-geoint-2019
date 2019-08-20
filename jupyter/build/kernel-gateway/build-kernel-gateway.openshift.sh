#!/usr/bin/env bash

# see https://github.com/jupyter/kernel_gateway
# see https://jupyter-kernel-gateway.readthedocs.io/en/latest/getting-started.html

sudo podman build -t jupyter-kernel-gateway .
podman run -it --rm -p 8080:8080 jupyter-kernel-gateway

echo "Done."
