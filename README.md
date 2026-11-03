# Photon Docker

Runs PHP 8.4 FPM with Photon SVN revision 664 and the required Photon-OpenCV 0.2.40 backend. The multi-platform image is published as [`ghcr.io/wpelevator/photon-php-fpm:1.0.0`](https://github.com/wpelevator/basement/pkgs/container/photon-php-fpm) for use outside this repository.

The image includes [a custom config file](config/photon/config.php) at `/var/www/photon/config.php`. It hooks into Photon URL loading and fetches original images from `/var/www/photon/uploads` instead of an origin server.

The request `REQUEST_URI` should be `/some/path/to/file.jpeg` to process a file mounted at `/var/www/photon/uploads/some/path/to/file.jpeg`.

The FastCGI parameters should be configured as follows:

    DOCUMENT_ROOT /var/www/photon
    SCRIPT_FILENAME /var/www/photon/index.php
    SCRIPT_NAME /index.php

## Use the image

Pull the published image for AMD64 or ARM64:

```bash
docker pull ghcr.io/wpelevator/photon-php-fpm:1.0.0
```

1. Mount your uploads directory to `/var/www/photon/uploads/project-name` as read-only.
2. Configure your web server to forward requests for `/wp-content/uploads/...` to port `9000` of the container with the request URI rewritten to `/project-name/...`.

## Build

Build the image through the repository's Docker development environment:

```bash
docker compose build photon
```

The Dockerfile keeps Photon, PHP-CPP and Photon-OpenCV in independent build layers so unchanged upstream inputs remain cached. Subversion, extension source and Debian development packages are excluded from the final runtime image.

## Release

The image is released like the other packages, with a changeset and a package tag like `docker/photon-php-fpm/1.1.0`. Add a changeset with `npm run wp-release -- changeset-add` when a change to the Dockerfile, the Photon revision, PHP or the config affects the image, for example a `PHP_VERSION` or `PHOTON_REVISION` update.

The package tag runs the `Docker Images` workflow, which builds the image for AMD64 and ARM64 and publishes it to GitHub Container Registry as `1.1.0`, `1.1` and `1`. A released version tag is never overwritten. Pushes to `main` publish the `edge` tag only.

## Other examples

- [WP VIP Photon image](https://github.com/Automattic/vip-container-images/tree/e7dc29450c2d3c6c5f0b0b50156b303a171c9670/photon)
