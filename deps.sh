#!/bin/sh

if [ -e apt-get ]; then
  apt-get install -y jq curl
elif [ -e yum ]; then
  yum install jq curl
elif [ -e apk ]; then
  apk add --no-cache jq curl
fi
