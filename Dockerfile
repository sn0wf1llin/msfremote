# ##############################################################################
# docker run -it --name msf --volume=/tmp/data:/tmp/data msf
# docker build --build-arg MSF_DB_USER=msfuser --build-arg MSF_DB_PASSWORD=msfadmin . -t msfremote
# docker run -e "TEST_RESOURCE_FILE_LINK=https://github.com/bluscreenofjeff/Metasploit-Resource-Scripts/blob/master/infogather.rc" --volume=/tmp/data:/tmp/data --name msf msf
# ##############################################################################

FROM				debian:stretch
MAINTAINER 	NS <sn0wf1llin>

ARG					msf_db_user="msf"
ARG					msf_db_password="msf"
ARG					MSF_DB="msfdb"
ARG					ruby_version="2.6.5"
ARG 				resource_file_url="https://raw.githubusercontent.com/TIGER-Framework/tiger_msf_tests/msfdocker/test_resource_file/test.rc"
ENV					TEST_RESOURCE_FILE_LINK=${resource_file_url} RUBY_VERSION=${ruby_version} MSF_DB_USER=${msf_db_user} MSF_DB_PASSWORD=${msf_db_password}
ENV					PATH="/usr/local/rvm/bin:/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/bin:$PATH:$HOME/.rvm/bin"
WORKDIR 		/opt
USER 				root

RUN 	apt-get update && apt-get -y install git build-essential zlib1g zlib1g-dev \
		  libxml2 libxml2-dev libxslt-dev locate curl libreadline6-dev libcurl4-openssl-dev git-core \
  		libssl-dev libyaml-dev openssl autoconf libtool ncurses-dev bison curl wget xsel postgresql \
  		postgresql-contrib postgresql-client libpq-dev libapr1 libaprutil1 libsvn1 \
  		libpcap-dev libsqlite3-dev libgmp3-dev nasm tmux vim nmap tcpdump lsof && \
			rm -rf /var/lib/apt/lists/*

RUN		curl -sSL https://github.com/REMnux/docker/raw/master/metasploit/conf/tmux.conf --output /root/.tmux.conf

RUN 	git clone https://github.com/rapid7/metasploit-framework.git

RUN		printf "update pg_database set datallowconn = TRUE where datname = 'template0';\n\\c template0\n" > /tmp/db.sql && \
			printf "update pg_database set datistemplate = FALSE where datname = 'template1';\ndrop database template1;\n" >> /tmp/db.sql && \
			printf "create database template1 with template = template0 encoding = 'UTF8';\nupdate pg_database set datistemplate = TRUE where datname = 'template1';\n" >> /tmp/db.sql && \
			printf "\\c template1\nupdate pg_database set datallowconn = FALSE where datname = 'template0';\ncreate user ${MSF_DB_USER};\n" >> /tmp/db.sql && \
			printf "alter user ${MSF_DB_USER} with encrypted password '${MSF_DB_PASSWORD}';\nalter user ${MSF_DB_USER} CREATEDB;\n\\q" >> /tmp/db.sql

RUN		/etc/init.d/postgresql start && \
			su postgres -c "psql -f /tmp/db.sql" && \
			printf "production:\n    adapter: postgresql\n    database: ${MSF_DB}\n    username: ${MSF_DB_USER}\n    password: ${MSF_DB_PASSWORD}\n    host: 127.0.0.1\n    port: 5432\n    pool: 75\n    timeout: 5" > /opt/metasploit-framework/config/database.yml

RUN 	curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
			curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -

WORKDIR	/opt/metasploit-framework

RUN		curl -L https://get.rvm.io | bash -s stable

RUN 	/bin/bash -l -c "rvm requirements"

RUN		/bin/bash -l -c "rvm install ${RUBY_VERSION}"

RUN		/bin/bash -l -c "rvm use ${RUBY_VERSION} --default"

RUN		/bin/bash -l -c "source /usr/local/rvm/scripts/rvm"

RUN		/bin/bash -l -c "gem install bundler --no-document"

RUN		/bin/bash -l -c "source /usr/local/rvm/scripts/rvm && which bundle"

RUN		/bin/bash -l -c "which bundle"

RUN 	/bin/bash -l -c "BUNDLEJOBS=$(expr $(cat /proc/cpuinfo | grep vendor_id | wc -l) - 1)"

RUN		/bin/bash -l -c "bundle config --global jobs $BUNDLEJOBS"

RUN		/bin/bash -l -c "bundle install"

RUN 	for i in `ls /opt/metasploit-framework/tools/*/*`; do ln -s $i /usr/local/bin/; done

RUN		ln -s /opt/metasploit-framework/msf* /usr/local/bin

RUN		rvm use default && \
			bundle install

RUN		mkdir -p /tmp/data && \
			mkdir -p /tmp/tests && \
			echo "${TEST_RESOURCE_FILE_LINK}" && \
			curl -sSL "${TEST_RESOURCE_FILE_LINK}" --output /tmp/tests/test.rc
			# msfconsole -r test.rc 2>test.rc_errors.txt 1>test.rc_results.txt

VOLUME /root/.msf4/
VOLUME /tmp/data/

RUN 	mkdir -p /var/spool/cron && \
			touch /var/spool/cron/root && \
			/usr/bin/crontab /var/spool/cron/root && \
			echo "10 * * * * root shutdown -h now" >> /var/spool/cron/root && \
			crontab -u root -l

RUN echo '#!/bin/bash' > /usr/local/bin/init.sh && \
		printf "\n\nset -e\nsource /usr/local/rvm/scripts/rvm\nservice postgresql start && echo \"PostgreSQL started [OK]\" || echo \"PostgreSQL started [FAIL]\"" >> /usr/local/bin/init.sh && \
		printf "\ncp /tmp/tests/test.rc /tmp/data/test.rc" >> /usr/local/bin/init.sh && \
		printf "\nmsfconsole -r /tmp/tests/test.rc 2>/tmp/data/test.rc_errors.txt 1>/tmp/data/test.rc_results.txt">> /usr/local/bin/init.sh && \
		chmod a+xr /usr/local/bin/init.sh

CMD /usr/local/bin/init.sh
