FROM php:5.6-fpm-jessie

RUN apt-get update

# DEBIAN_DPKGS BEGIN
RUN set -ex \
  && apt-get install -y --no-install-recommends git-core htop screen \
    apt-transport-https vim libmysqlclient-dev bzip2 libfontconfig mysql-client rsync \
    supervisor openssh-server cron ca-certificates nginx locales php5-mysql php5-gd \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# DEBIAN_DPKGS END

# SUPERVISOR BEGIN
RUN set -ex \
  && mkdir -p /var/log/supervisor \
  && { \
    echo '[supervisord]'; \
    echo 'nodaemon=true'; \
  } >> /etc/supervisor/conf.d/supervisord.conf

# SUPERVISOR END

# SSH_SERVER BEGIN
RUN set -ex \
  && mkdir -p /var/run/sshd \
  && { \
    echo '[program:sshd]'; \
    echo 'command=/usr/sbin/sshd -D'; \
  } >> /etc/supervisor/conf.d/sshd.conf

# SSH_SERVER END

# CRON_SERVER BEGIN
RUN set -ex \
  && { \
    echo '[program:cron]'; \
    echo 'command=/usr/sbin/cron -f'; \
  } >> /etc/supervisor/conf.d/cron.conf

# CRON_SERVER END

# NGINX_SERVER BEGIN
RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
  && echo "deb http://nginx.org/packages/debian/ $(awk -F"[)(]+" '/VERSION=/ {print $2}' /etc/os-release) nginx" >> /etc/apt/sources.list \
  && apt-get update \
  && { \
    echo '[program:nginx]'; \
    echo 'command=nginx -g "daemon off;"'; \
  } >> /etc/supervisor/conf.d/nginx.conf

# NGINX_SERVER END

# LOCALE BEGIN
RUN set -ex \
  && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en:

ENV LC_ALL en_US.UTF-8

# LOCALE END

# TIMEZONE BEGIN
RUN set -ex \
  && echo "Asia/Shanghai" > /etc/timezone \
  && dpkg-reconfigure -f noninteractive tzdata

# TIMEZONE END

# SSH_AGENT BEGIN
RUN set -ex \
  && mkdir -p /root/.ssh /root/.bash.d \
  && { \
    echo 'Host *'; \
    echo 'ServerAliveInterval=15'; \
    echo 'ServerAliveCountMax=6'; \
    echo 'ForwardAgent yes'; \
  } >> /root/.ssh/config \
  && { \
    echo 'source ~/.bash.d/10_ssh-agent.bash'; \
  } >> /root/.bashrc

RUN set -ex \
  && cd /root/.bash.d \
  && curl -SLO https://raw.githubusercontent.com/agideo/docker-baseimage/master/files/bash.d/10_ssh-agent.bash \
  && cd -

# SSH_AGENT END


# DEBIAN_CLEAN END

# DOTBASHRC BEGIN
RUN set -ex \
  && { \
    echo "export TERM=xterm"; \
    echo "export PATH=$(echo $PATH)"; \
  } >> /root/.bashrc

# DOTBASHRC END


# php-fpm

RUN set -ex \
  && { \
    echo '[program:php-fpm]'; \
    echo 'command=bash -lc "php-fpm -D"'; \
    echo 'stdout_logfile=/dev/stdout'; \
    echo 'redirect_stderr=true'; \
  } >> /etc/supervisor/conf.d/php-fpm.conf


RUN mkdir /app
WORKDIR /app
VOLUME /app

EXPOSE 22 80 3000
CMD ["/usr/bin/supervisord"]
