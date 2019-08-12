FROM alpine:3.5

ENV PATH=$PATH:/usr/share/metasploit-framework 
ENV NOKOGIRI_USE_SYSTEM_LIBRARIES=1
RUN echo -e "http://nl.alpinelinux.org/alpine/v3.5/main\nhttp://nl.alpinelinux.org/alpine/v3.5/community" > /etc/apk/repositories
RUN apk update && \
	apk add \
	build-base \
	ruby \
	ruby-bigdecimal \
	ruby-bundler \
	ruby-io-console \
	ruby-dev \
	libffi-dev\
        libressl-dev \
	readline-dev \
	sqlite-dev \
	postgresql-dev \
        libpcap-dev \
	libxml2-dev \
	libxslt-dev \
	yaml-dev \
	zlib-dev \
	ncurses-dev \
        autoconf \
	bison \
	subversion \
	git \
	sqlite \
	nmap \
	lsof \
	tcpdump \
	net-tools \
	binutils \
	libxslt \
	postgresql \
        ncurses 

RUN cd /usr/share && \
    git clone https://github.com/rapid7/metasploit-framework.git && \
    cd /usr/share/metasploit-framework && \
    bundle install

RUN apk del \
	build-base \
	ruby-dev \
	libffi-dev\
        libressl-dev \
	readline-dev \
	sqlite-dev \
	postgresql-dev \
        libpcap-dev \
	libxml2-dev \
	libxslt-dev \
	yaml-dev \
	zlib-dev \
	ncurses-dev \
	bison \
	autoconf \
	&& rm -rf /var/cache/apk/*

EXPOSE 55553/tcp
EXPOSE 8080/tcp
EXPOSE 8443/tcp

CMD /usr/share/metasploit-framework/msfrpcd -U msf -P msf -S -f

