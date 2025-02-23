#!/bin/bash
sudo podman build . -t docker.io/meuna/lsdc2:valheim --format docker
sudo docker push docker.io/meuna/lsdc2:valheim