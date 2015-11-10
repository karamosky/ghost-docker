FROM node:0.10-slim

MAINTAINER Karam EL HABOUTI <karam@elhabouti.com>
RUN groupadd user && useradd --create-home --home-dir /home/user -g user user

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends curl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN curl -o /usr/local/bin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture)" \
		&& chmod +x /usr/local/bin/gosu

ENV GHOST_SOURCE /usr/src/ghost
WORKDIR $GHOST_SOURCE

ENV GHOST_VERSION 0.7.1
# NODE_PORT ==> Port where pm2 will bind
ENV NODE_PORT 2368
# Mailgun configs
ENV MAILGUN_USER postmaster@example.com
ENV MAILGUN_PASSWORD secret
# Mail from configs
ENV MAIL_FROM_NAME "Your Name"
ENV MAIL_FROM_ADDRESS yourmail@example.com
# Ghost url
ENV GHOST_URL http://blog.example.com

RUN buildDeps=' \
		gcc \
		make \
		python \
		unzip \
	' \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& curl -sSL "https://ghost.org/archives/ghost-${GHOST_VERSION}.zip" -o ghost.zip \
	&& unzip ghost.zip \
	&& npm install --production \
	&& npm install pm2 -g \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps \
	&& rm ghost.zip \
	&& npm cache clean \
	&& rm -rf /tmp/npm*

ADD config.example.js config.example.js
ENV GHOST_CONTENT /var/lib/ghost
RUN mkdir -p "$GHOST_CONTENT" && chown -R user:user "$GHOST_CONTENT"
VOLUME $GHOST_CONTENT

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE $NODE_PORT
CMD ["pm2", "start","index.js","--no-daemon"]
