<?php
/**
 * Configure Photon to load images from the local filesystem
 * instead of fetching from the origin server.
 *
 * Expects uploads directories to be mounted under at /var/www/photon/uploads/<project-name>/<path>
 * and the REQUEST_URI to be /<project-name>/<path>. Skip the <project-name> part if only
 * one application is mounted to this container.
 */

define( 'OPTIPNG', '/usr/bin/optipng' );
define( 'PNGQUANT', '/usr/bin/pngquant' );
define( 'PNGCRUSH', '/usr/bin/pngcrush' );
define( 'CWEBP', '/usr/bin/cwebp' );
define( 'JPEGOPTIM', '/usr/bin/jpegoptim' );
define( 'JPEGTRAN', '/usr/bin/jpegtran' );

add_filter(
	'override_raw_data_fetch',
	function ( $data, $url ) {
		$url_parts = parse_url( $url );

		if ( ! empty( $url_parts['host'] ) && ! empty( $url_parts['path'] ) ) {
			$local_path = sprintf( '/var/www/photon/uploads/%s/%s', $url_parts['host'], ltrim( $url_parts['path'], '/\\' ) );

			if ( is_readable( $local_path ) ) {
				return file_get_contents( $local_path );
			}
		}

		return false; // Prevent any origin lookups over HTTP.
	},
	10,
	2
);
