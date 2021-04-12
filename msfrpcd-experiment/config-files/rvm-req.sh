#!/bin/bash

set -e

RUBY_VERSION="$1"

if [ -z $RUBY_VERSION ]; then echo "No RUBY_VERSION provided."; exit 1; fi;

source /usr/local/rvm/scripts/rvm
rvm requirements
rvm install ${RUBY_VERSION}
rvm use ${RUBY_VERSION} --default
gem install bundler --no-document
BUNDLEJOBS=$(expr $(cat /proc/cpuinfo | grep vendor_id | wc -l) - 1)
BUNDLE_BINARY=$(which bundle)
$BUNDLE_BINARY config --global jobs $BUNDLEJOBS
$BUNDLE_BINARY install
