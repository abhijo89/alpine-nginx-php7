FROM shito/alpine-nginx:edge
MAINTAINER Abhilash Joseph C <abhilash@softlinkweb.com>
# Wordpress Version
ENV WORDPRESS_VERSION 4.2.1
ENV WORDPRESS_SHA1 c93a39be9911591b19a94743014be3585df0512f

# Add PHP 7
RUN apk upgrade -U && \
    apk --update --repository=http://dl-4.alpinelinux.org/alpine/edge/testing add \
    openssl \
    php7 \
    php7-xml \
    php7-xsl \
    php7-pdo \
    php7-mcrypt \
    php7-curl \
    php7-json \
    php7-fpm \
    php7-phar \
    php7-openssl \
    php7-mysqli \
    php7-ctype \
    php7-opcache \
    php7-mbstring \
    php7-session \
    php7-pcntl \
    mysql \
    mysql-client

COPY /rootfs /

# Small fixes
RUN ln -s /etc/php7 /etc/php && \
    ln -s /usr/bin/php7 /usr/bin/php && \
    ln -s /usr/sbin/php-fpm7 /usr/bin/php-fpm && \
    ln -s /usr/lib/php7 /usr/lib/php && \
    rm -fr /var/cache/apk/* 
# Some Mysql Fixes
RUN mkdir -p /var/lib/mysql && \
    mkdir -p /etc/mysql/conf.d && \
    { \
        echo '[mysqld]'; \
        echo 'user = root'; \
        echo 'datadir = /var/lib/mysql'; \
        echo 'port = 3306'; \
        echo 'log-bin = /var/lib/mysql/mysql-bin'; \
        echo 'socket = /var/lib/mysql/mysql.sock'; \
        echo '!includedir /etc/mysql/conf.d/'; \
    } > /etc/mysql/my.cnf && \
    rm -rf /var/cache/apk/*

VOLUME ["/var/lib/mysql", "/etc/mysql/conf.d/"]
EXPOSE 3306
CMD ["--skip-grant-tables"]

# Install composer global bin
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Enable default sessions
RUN mkdir -p /var/lib/php7/sessions
RUN chown nginx:nginx /var/lib/php7/sessions

# ADD SOURCE
RUN mkdir -p /usr/share/nginx/html
RUN chown -Rf nginx:nginx /usr/share/nginx/html

RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
        && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
        && tar -xzf wordpress.tar.gz -C /usr/share/nginx/html/ \
        && rm wordpress.tar.gz \
        && chown -R www-data:www-data /usr/share/nginx/html/wordpress

ENTRYPOINT ["/init"]
