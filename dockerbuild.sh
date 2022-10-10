#!/bin/bash
#
# Builds and pushes docker images for services used by CI and localdev
set -ue
set -x

declare -A projects=(\
    ["postgres"]="13.3-alpine"\
    ["rabbitmq"]="3.9.7-management-alpine"\
    ["bitnami/redis"]="4.0"\
    )

# Should be set before running, else -u will exit non 0.
echo "DOCKER_REMOTE=$DOCKER_REMOTE"
export DOC_REPO="$DOCKER_REMOTE/services"

function build_step() {
  # Builds a single target step in a multi-step build
  local imagetag="$1"
  local dockerpath="${DOC_REPO}/${imagetag}"
  local dockerfile=$(echo ${imagetag}.Dockerfile |sed -r 's#[:/]#-#g')

  echo "dockerpath: $dockerpath"
  echo "dockerfile: $dockerfile"

  docker pull $imagetag

  user=$(
    docker inspect \
      -f '{{ .Config.User }}' \
      "$imagetag"
  )

  echo FROM $imagetag > $dockerfile
  [ -n "$user" ] && echo USER root >> $dockerfile
  cat body.Dockerfile >> $dockerfile
  [ -n "$user" ] && echo USER $(
    docker inspect \
      -f '{{ .Config.User }}' \
      "$imagetag"
  ) >> "$dockerfile"
  echo ENTRYPOINT $(
    docker inspect \
      -f '{{ .Config.Entrypoint | json }}' \
      "$imagetag" \
    | sed 's#^.#["/usr/local/bin/kubernetes-vault-wrapper.sh",#'
  ) >> "$dockerfile"
  echo CMD $(
    docker inspect \
      -f '{{ .Config.Cmd | json }}' \
      "$imagetag" \
  ) >> "$dockerfile"

  echo "BUILDING $dockerpath with Dockerfile:"
  echo "---------"
  cat "$dockerfile"
  echo "---------"

  docker build \
    -t $dockerpath \
    -f "$dockerfile" \
    .
  echo docker push $dockerpath
}
export -f build_step
for project in "${!projects[@]}"; do
  echo "$project:${projects[$project]}"
done | parallel build_step
