#!/bin/bash
podman build . -t docker.io/meuna/lsdc2:valheim --format docker
podman push docker.io/meuna/lsdc2:valheim