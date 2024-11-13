FROM php:8.3-fpm-bookworm

RUN apt-get update \
	&& apt-get install --yes --no-install-recommends \
		curl subversion netbase libfreetype-dev libcurl4-openssl-dev \
		libjpeg62-turbo-dev jpegoptim libjpeg-turbo-progs \
		libpng-dev optipng pngcrush pngquant \
		libwebp-dev webp \
		graphicsmagick-libmagick-dev-compat \
	&& rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) gd curl

RUN pecl install gmagick-2.0.6RC1 \
	&& docker-php-ext-enable gmagick

COPY --chown=www-data:www-data config/photon/config.php /var/www/photon/config.php

RUN svn checkout --non-interactive http://code.svn.wordpress.org/photon/ /var/www/photon \
	&& rm -rf /var/www/photon/.svn /var/www/photon/tests \
	&& chown -R www-data:www-data /var/www/photon

RUN install --directory --mode=0755 --owner=www-data /var/www/photon/uploads

VOLUME /var/www/photon/uploads
