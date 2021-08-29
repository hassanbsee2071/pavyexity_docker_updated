FROM php:7.4-fpm
ENV ACCEPT_EULA=Y
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    -y mariadb-client \
    gnupg \
    wget
# Microsoft SQL Server Prerequisites
RUN apt-get update
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get install -y --no-install-recommends locales apt-transport-https
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen
RUN wget http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1.4_amd64.deb
RUN apt-get install ./multiarch-support_2.27-3ubuntu1.4_amd64.deb
RUN apt-get update -y 
RUN apt install libodbc1 -y
RUN apt-get -y --no-install-recommends install unixodbc-dev msodbcsql17
RUN docker-php-ext-install zip exif pcntl bcmath gd mbstring pdo pdo_mysql && pecl install sqlsrv pdo_sqlsrv xdebug && docker-php-ext-enable sqlsrv pdo_sqlsrv xdebug
RUN echo "test" > /root/test.txt
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
# Create system user to run Composer and Artisan Commands
# RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

RUN echo "test 2" >> /root/test.txt

RUN apt-get update -y \
    && apt-get install -y nginx && apt install net-tools vim  -y

# PHP_CPPFLAGS are used by the docker-php-ext-* scripts
ENV PHP_CPPFLAGS="$PHP_CPPFLAGS -std=c++11"

RUN docker-php-ext-install pdo_mysql \
    && docker-php-ext-install opcache \
    && apt-get install libicu-dev -y \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && apt-get remove libicu-dev icu-devtools -y
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/php-opocache-cfg.ini

COPY default.conf /etc/nginx/conf.d/
RUN cat /etc/nginx/conf.d/default.conf > /etc/nginx/sites-enabled/default
COPY .env /root/.env
RUN export $(grep -v '^#' /root/.env | xargs -d '\n')
COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh


WORKDIR /var/www
RUN composer install
EXPOSE 80

ENTRYPOINT ["/etc/entrypoint.sh"]
