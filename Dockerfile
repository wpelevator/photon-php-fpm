# syntax=docker/dockerfile:1.7

ARG PHP_VERSION=8.4

FROM php:${PHP_VERSION}-fpm-trixie AS extension

ARG PHP_CPP_VERSION=v2.4.18
# photon-opencv 0.2.40 has not been tagged yet, so pin its version commit.
ARG PHOTON_OPENCV_REF=db14aa988c39098cb1d4b9c1491913ca412ba0b4

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	apt-get update \
	&& apt-get install --yes --no-install-recommends \
		build-essential ca-certificates git pkg-config \
		libexiv2-dev libfreetype-dev libgif-dev libheif-dev \
		libjpeg62-turbo-dev liblcms2-dev libopencv-dev libpng-dev libwebp-dev

WORKDIR /build

RUN git clone --depth 1 --branch "${PHP_CPP_VERSION}" https://github.com/CopernicaMarketingSoftware/PHP-CPP.git \
	&& make -C PHP-CPP -j"$(nproc)" \
	&& make -C PHP-CPP install

RUN git init photon-opencv \
	&& git -C photon-opencv remote add origin https://github.com/Automattic/photon-opencv.git \
	&& git -C photon-opencv fetch --depth 1 origin "${PHOTON_OPENCV_REF}" \
	&& git -C photon-opencv checkout --detach FETCH_HEAD \
	&& make -C photon-opencv -j"$(nproc)" PHP_CONFIG=php-config \
	&& make -C photon-opencv install PHP_CONFIG=php-config

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
	&& docker-php-ext-install -j"$(nproc)" gd

RUN strip --strip-unneeded "$(readlink -f /usr/lib/libphpcpp.so.2.4)" "$(php-config --extension-dir)/photon-opencv.so" \
	&& mkdir /runtime-root \
	&& cp --archive --parents \
		/usr/lib/libphpcpp.so.* \
		"$(php-config --extension-dir)/gd.so" \
		"$(php-config --extension-dir)/photon-opencv.so" \
		/runtime-root


FROM debian:trixie-slim AS photon

ARG PHOTON_REVISION=664

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	apt-get update \
	&& apt-get install --yes --no-install-recommends ca-certificates subversion

RUN svn export --non-interactive -r "${PHOTON_REVISION}" https://code.svn.wordpress.org/photon/ /var/www/photon \
	&& rm -rf /var/www/photon/tests

FROM php:${PHP_VERSION}-fpm-trixie

LABEL org.opencontainers.image.source="https://github.com/wpelevator/basement" \
	org.opencontainers.image.documentation="https://github.com/wpelevator/basement/blob/main/packages/docker/photon-php-fpm/README.md" \
	org.opencontainers.image.title="Photon PHP-FPM" \
	org.opencontainers.image.description="A PHP-FPM runtime for the Photon image service" \
	org.opencontainers.image.licenses="GPL-2.0-or-later"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	apt-get update \
	&& apt-get install --yes --no-install-recommends \
		ca-certificates curl jpegoptim libexiv2-28 libfreetype6 libgif7 \
		libheif1 libheif-plugin-dav1d libheif-plugin-libde265 libjpeg62-turbo \
		libjpeg-turbo-progs liblcms2-2 libopencv-core410 libopencv-imgcodecs410 \
		libopencv-imgproc410 libpng16-16t64 libwebp7 libwebpdemux2 libwebpmux3 \
		netbase optipng pngcrush pngquant webp

COPY --from=extension /runtime-root/ /

RUN ldconfig \
	&& docker-php-ext-enable gd photon-opencv \
	&& php -r 'exit(extension_loaded("photon-opencv") ? 0 : 1);'

COPY --from=photon --chown=www-data:www-data /var/www/photon /var/www/photon
COPY --chown=www-data:www-data config/photon/config.php /var/www/photon/config.php

RUN install --directory --mode=0755 --owner=www-data --group=www-data /var/www/photon/uploads

VOLUME /var/www/photon/uploads
