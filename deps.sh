#!/bin/sh

set -e

if [ -e apt-get ]; then
  apt-get install -y jq curl
elif [ -e yum ]; then
  yum install jq curl
elif [ -e apk ]; then
  apk add --no-cache jq curl
else
  echo Unsupported platform >&2
  exit 1
fi
