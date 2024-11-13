# Photon Docker

Runs `php8.3-fpm` with Photon pulled [from SVN](http://code.svn.wordpress.org/photon/) into `/var/www/photon` with [a custom config file](config/photon/config.php) copied to `/var/www/config.php` which hooks into Photon URL loading and fetches the original images from the `/var/www/photon/uploads` directory instead.

The request `REQUEST_URI` should be `/some/path/to/file.jpeg` to Photonize a file mounted at `/var/www/photon/uploads/some/path/to/file.jpeg`.

The fastcgi parameters should be configured as follows:

    DOCUMENT_ROOT /var/www/photon
    SCRIPT_FILENAME /var/www/photon/index.php
    SCRIPT_NAME /index.php

## Configure

1. Mount your uploads directory to `/var/www/photon/uploads/project-name` (consider using the `ro` flag).
2. Configure your web server to forward requests for `/wp-content/uploads/..` to fastcgi container `:9000` with request URI rewritten to `/uploads/project-name/...`.

## To Do

- [ ] Document an example with Nginx/Caddy.
- [ ] Push to GitHub registry.
- [ ] Reduce the 1.1GB image size (mostly due to image tools).

## Other Examples

- [WP VIP Photon image](https://github.com/Automattic/vip-container-images/tree/e7dc29450c2d3c6c5f0b0b50156b303a171c9670/photon)
