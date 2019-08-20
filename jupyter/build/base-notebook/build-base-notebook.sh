#!/usr/bin/env bash

# see https://necromuralist.github.io/posts/building-a-jupyter-docker-container/
# see https://jupyter-kernel-gateway.readthedocs.io/en/latest/getting-started.html

sudo podman build -t jupyter-kernel-gateway .
podman run -it --rm -p 8080:8080 jupyter-kernel-gateway

echo "Done."
