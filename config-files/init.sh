#!/bin/bash

set -e

if [ -z $TEST_RESOURCE_FILE_LINK ]; then echo "No TEST_RESOURCE_FILE_LINK provided."; exit 1; fi;

source /usr/local/rvm/scripts/rvm
service postgresql start && echo "PostgreSQL started [OK]" || echo "PostgreSQL started [FAIL]"
echo "Got <$TEST_RESOURCE_FILE_LINK> ... "
rm -f /tmp/tests/*
curl -sSL $TEST_RESOURCE_FILE_LINK --output /tmp/tests/test.rc
cp /tmp/tests/test.rc /tmp/data/test.rc
msfconsole -r /tmp/tests/test.rc 2>/tmp/data/test.rc_errors.txt 1>/tmp/data/test.rc_results.txt
