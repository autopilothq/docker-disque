FROM debian:jessie
MAINTAINER Richard North <rich.north@gmail.com>

ENV version 1.0-rc1

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r disque && useradd -r -g disque disque

# Add general dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
	&& rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" \
	&& curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu

# Add build-time dependencies to remove later
RUN apt-get update && apt-get install -y --no-install-recommends \
		gcc libc6-dev make tcl git && \
	rm -rf /var/lib/apt/lists/* && \
# Obtain disque sources
	git clone https://github.com/antirez/disque.git && \
	cd disque && \
	git checkout 0192ba7e1cda157024229962b7bee1c6e86d771b && \
# Make disque
	make install && \
	make test && \
	mv src/disque-server /usr/bin && \
	mv src/disque /usr/bin && \
# Clean up
	rm -rf /disque-${version} && \
	apt-get purge -y --auto-remove gcc libc6-dev make tcl

RUN mkdir /data && chown disque:disque /data
VOLUME /data
WORKDIR /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 7711 17711

CMD [ "disque-server" ]
