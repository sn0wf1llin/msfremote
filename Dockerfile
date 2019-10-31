# ##############################################################################
# docker run -it --name msf --volume=/tmp/data:/tmp/data msf
# docker build --build-arg MSF_DB_USER=msfuser --build-arg MSF_DB_PASSWORD=msfadmin . -t msfremote
# docker run -e TEST_RESOURCE_FILE_LINK="https://raw.githubusercontent.com/bluscreenofjeff/Metasploit-Resource-Scripts/master/infogather.rc" --volume=/tmp/data:/tmp/data --name msf msf
# ##############################################################################

FROM				debian:stretch
MAINTAINER 	NS <sn0wf1llin>

ARG					msf_db_user="msf"
ARG					msf_db_password="msf"
ARG					MSF_DB="msfdb"
ARG					ruby_version="2.6.5"

ENV					RUBY_VERSION=${ruby_version} MSF_DB_USER=${msf_db_user} MSF_DB_PASSWORD=${msf_db_password} PATH="/usr/local/rvm/bin:/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/bin:$PATH:$HOME/.rvm/bin" TEST_RESOURCE_FILE_LINK='https://raw.githubusercontent.com/TIGER-Framework/tiger_msf_tests/msfdocker/test_resource_file/test.rc'

WORKDIR 		/opt
USER 				root

# RUN		curl -sSL https://github.com/REMnux/docker/raw/master/metasploit/conf/tmux.conf --output /root/.tmux.conf
COPY 	config-files/* /usr/local/bin/

RUN 	apt-get update && apt-get -y install git build-essential zlib1g zlib1g-dev \
		  libxml2 libxml2-dev libxslt-dev locate curl libreadline6-dev libcurl4-openssl-dev git-core \
  		libssl-dev libyaml-dev openssl autoconf libtool ncurses-dev bison curl wget xsel postgresql \
  		postgresql-contrib postgresql-client libpq-dev libapr1 libaprutil1 libsvn1 \
  		libpcap-dev libsqlite3-dev libgmp3-dev nasm tmux vim nmap tcpdump lsof && \
			rm -rf /var/lib/apt/* && \
			apt-get autoclean && \
			apt-get autoremove

RUN 	chmod a+xr /usr/local/bin/*.sh && \
			curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
			curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -

# RUN 	git clone https://github.com/rapid7/metasploit-framework.git
RUN 	mkdir -p /opt/metasploit-framework
ADD 	metasploit-framework /opt/metasploit-framework

RUN		printf "update pg_database set datallowconn = TRUE where datname = 'template0';\n\\c template0\n" > /usr/local/bin/db.sql && \
			printf "update pg_database set datistemplate = FALSE where datname = 'template1';\ndrop database template1;\n" >> /usr/local/bin/db.sql && \
			printf "create database template1 with template = template0 encoding = 'UTF8';\nupdate pg_database set datistemplate = TRUE where datname = 'template1';\n" >> /usr/local/bin/db.sql && \
			printf "\\c template1\nupdate pg_database set datallowconn = FALSE where datname = 'template0';\ncreate user ${MSF_DB_USER};\n" >> /usr/local/bin/db.sql && \
			printf "alter user ${MSF_DB_USER} with encrypted password '${MSF_DB_PASSWORD}';\nalter user ${MSF_DB_USER} CREATEDB;\n\\q" >> /usr/local/bin/db.sql

RUN		/etc/init.d/postgresql start && \
			su postgres -c "psql -f /usr/local/bin/db.sql" && \
			printf "production:\n    adapter: postgresql\n    database: ${MSF_DB}\n" > /opt/metasploit-framework/config/database.yml && \
			printf "    username: ${MSF_DB_USER}\n    password: ${MSF_DB_PASSWORD}\n" >> /opt/metasploit-framework/config/database.yml && \
			printf "    host: 127.0.0.1\n    port: 5432\n    pool: 75\n    timeout: 5" >> /opt/metasploit-framework/config/database.yml

WORKDIR	/opt/metasploit-framework

RUN		curl -L https://get.rvm.io | bash -s stable

RUN		/usr/local/bin/rvm-req.sh ${RUBY_VERSION}

RUN 	for i in `ls /opt/metasploit-framework/tools/*/*`; do ln -s $i /usr/local/bin/; done

RUN 	ln -s /opt/metasploit-framework/msf* /usr/local/bin

VOLUME /root/.msf4/
VOLUME /tmp/data/

RUN 	/usr/local/bin/cron-kill.sh

RUN		mkdir -p /tmp/data && \
			mkdir -p /tmp/tests

CMD ["/usr/local/bin/init.sh"]
