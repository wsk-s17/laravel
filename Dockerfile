FROM node:22 as node

FROM php:8.4-apache

RUN apt-get update -y && apt-get install -y \
    openssl \
    zip \
    unzip \
    zlib1g-dev \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    curl \
    libpng-dev \
    nano \
    git \
    cron \
    inetutils-ping \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql zip gd exif \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local/bin/ /usr/local/bin/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /opt/ /opt/

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

COPY httpd-vhosts.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

RUN echo "max_execution_time = 1200" > /usr/local/etc/php/conf.d/execution.ini \
    && echo "memory_limit = 2048M" >> /usr/local/etc/php/conf.d/execution.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/execution.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/execution.ini

WORKDIR /var/www/html/

COPY composer.json composer.lock* ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

RUN npm run build \
    && npm prune --production \
    && npm cache clean --force

RUN chown -R www-data:www-data /var/www/html

ENV APP_ENV=production
ENV DB_HOST=competitor_db

ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]