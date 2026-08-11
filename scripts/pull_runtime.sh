#!/usr/bin/env bash
set -Eeuo pipefail
IMAGE="${IMAGE:-ghcr.io/r0b0tlab/nemotron-lightning-repro-runtime:sm121-mtp1}"
docker pull "$IMAGE"
docker image inspect "$IMAGE" --format 'image={{.Id}} arch={{.Architecture}} os={{.Os}} size={{.Size}} repo_digests={{json .RepoDigests}} labels={{json .Config.Labels}}'
