# ##############################################################################
# docker run -it --name msf --volume=/tmp/data:/tmp/data msf
# docker build --build-arg MSF_DB_USER=msfuser --build-arg MSF_DB_PASSWORD=msfadmin . -t msfremote
# docker run -e TEST_RESOURCE_FILE_LINK="https://raw.githubusercontent.com/bluscreenofjeff/Metasploit-Resource-Scripts/master/infogather.rc" --volume=/tmp/data:/tmp/data --name msf msf
# ##############################################################################

FROM ubuntu:14.04
MAINTAINER			NS <sn0wf1llin>

ENV 				APP_HOME=/opt/metasploit-framework
ENV					TEST_RESOURCE_FILE_LINK='https://raw.githubusercontent.com/TIGER-Framework/tiger_msf_tests/msfdocker/test_resource_file/test.rc'

USER root

# Base packages
RUN apt-get update && apt-get -y install \
  git build-essential zlib1g zlib1g-dev \
  libxml2 libxml2-dev libxslt-dev locate curl \
  libreadline6-dev libcurl4-openssl-dev git-core \
  libssl-dev libyaml-dev openssl autoconf libtool \
  ncurses-dev bison curl wget xsel postgresql \
  postgresql-contrib postgresql-client libpq-dev \
  libapr1 libaprutil1 libsvn1 \
  libpcap-dev libsqlite3-dev libgmp3-dev \
  nasm tmux vim nmap \
  && rm -rf /var/lib/apt/lists/*

WORKDIR $APP_HOME

COPY 				./metasploit-framework $APP_HOME
COPY 				./config-files/db.sql /tmp/
COPY 				./config-files/*.sh /usr/local/bin/
RUN 				chmod a+xr /usr/local/bin/*.sh 

RUN /etc/init.d/postgresql start && su postgres -c "psql -f /tmp/db.sql"

COPY ./config-files/database.yml $APP_HOME/config/database.yml

RUN					mkdir -p /tmp/data && \
					mkdir -p /tmp/tests

# RVM
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
RUN curl -L https://get.rvm.io | bash -s stable 
RUN /usr/local/rvm/bin/rvm install "ruby-2.6.5"
RUN /usr/local/rvm/bin/rvm requirements
RUN /usr/local/rvm/bin/rvm use 2.6.5 --default
RUN /bin/bash -l -c "source /usr/local/rvm/scripts/rvm"
RUN /bin/bash -l -c "gem install bundler --no-document"
RUN /bin/bash -l -c "source /usr/local/rvm/scripts/rvm && which bundle"
RUN /bin/bash -l -c "which bundle"

# Get dependencies
RUN /bin/bash -l -c "BUNDLEJOBS=$(expr $(cat /proc/cpuinfo | grep vendor_id | wc -l) - 1)"
RUN /bin/bash -l -c "bundle config --global jobs $BUNDLEJOBS"
RUN /bin/bash -l -c "cd $APP_HOME; bundle install"

# Symlink tools to $PATH
RUN for i in `ls $APP_HOME/tools/*/*`; do ln -s $i /usr/local/bin/; done
RUN ln -s $APP_HOME/msf* /usr/local/bin
RUN chown -R msf:msf /var/run/postgresql
RUN /usr/local/bin/msf-user.sh
RUN echo "export PATH=\"/usr/local/rvm/gems/ruby-2.6.5@metasploit-framework/bin:/usr/local/rvm/gems/ruby-2.6.5@global/bin:/usr/local/rvm/rubies/ruby-2.6.5/bin:/usr/local/rvm/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/lib/postgresql/9.3/bin\"" >> ~/.bashrc


USER msf
RUN echo "export PATH=\"/usr/local/rvm/gems/ruby-2.6.5@metasploit-framework/bin:/usr/local/rvm/gems/ruby-2.6.5@global/bin:/usr/local/rvm/rubies/ruby-2.6.5/bin:/usr/local/rvm/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/lib/postgresql/9.3/bin\"" >> ~/.bashrc

USER root

# Configuration and sharing folders
VOLUME 				/root/.msf4/
VOLUME 				/tmp/data/

WORKDIR 			$APP_HOME

CMD ["/usr/local/bin/init.sh"]

# RUN 				/usr/local/bin/cron-kill.sh
