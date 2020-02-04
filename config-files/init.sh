# #! /bin/bash

# set -e

# apt-get install -y sudo
# useradd noroot && usermod -G sudo noroot

# service postgresql start
# export PATH="$PATH:/usr/local/rvm/rubies/default/bin"
# export PATH="$PATH:/usr/lib/postgresql/9.6/bin"
# mkdir -p /.msf4 && chown -R root:sudo /.msf4 && chmod u+w /.msf4
# cd /opt/metasploit-framework && bundle install

# # as noroot
# cd /opt/metasploit-framework

# export PATH="/usr/local/rvm/bin:/usr/local/rvm/rubies/ruby-/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/.rvm/bin:/usr/lib/postgresql/9.6/bin:/usr/local/rvm/src/ruby-2.6.5/bin:/usr/local/rvm/gems/ruby-2.6.5/bin:/usr/local/rvm/src/ruby-2.6.5"


# msfdb init
# # run resource-file test in background
# config-files/run-test.sh &
# RUN_TEST_PID=$!

# # wait 3m
# sleep 5m
#!/bin/bash
set -e

cd /opt/metasploit-framework

