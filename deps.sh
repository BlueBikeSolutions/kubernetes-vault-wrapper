#!/bin/sh

set -e

if which apt-get 2>&1 >/dev/null ; then
  apt-get update
  apt-get install -y jq curl
elif which yum 2>&1 >/dev/null ; then
  yum install jq curl
elif which apk 2>&1 >/dev/null ; then
  apk add --no-cache jq curl
else
  echo Unsupported platform >&2
  exit 1
fi
