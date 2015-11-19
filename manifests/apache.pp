# == Class owncloud::apache
#
# This class is called from owncloud.
#
class owncloud::apache {

  if $::owncloud::manage_apache {
    class { '::apache':
      default_vhost => false,
      mpm_module    => 'prefork',
      purge_configs => false,
    }

    include '::apache::mod::php', '::apache::mod::rewrite', '::apache::mod::ssl'
  }

  if $::owncloud::manage_vhost {
    $vhost_directories_common = {
        path            => $::owncloud::documentroot,
        options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
        allow_override  => 'All',
        custom_fragment => 'Dav Off',
      }

    if $::owncloud::apache_version == '2.2' {
      $vhost_directories_version = {
        order   => 'allow,deny',
        allow   => 'from All',
        satisfy => 'Any',
      }
    } else {
      $vhost_directories_version = {
        require => 'all granted'
      }
    }

    $vhost_directories = merge($vhost_directories_common, $vhost_directories_version)

    if $::owncloud::ssl {
      apache::vhost { 'owncloud-http':
        servername => $::owncloud::url,
        port       => $::owncloud::http_port,
        docroot    => $::owncloud::documentroot,
        rewrites   => [
          {
            comment      => 'redirect non-SSL traffic to SSL site',
            rewrite_cond => ['%{HTTPS} off'],
            rewrite_rule => ['(.*) https://%{HTTP_HOST}%{REQUEST_URI}'],
          }
        ]
      }

      apache::vhost { 'owncloud-https':
        servername  => $::owncloud::url,
        port        => $::owncloud::https_port,
        docroot     => $::owncloud::documentroot,
        directories => $vhost_directories,
        ssl         => true,
        ssl_ca      => $::owncloud::ssl_ca,
        ssl_cert    => $::owncloud::ssl_cert,
        ssl_chain   => $::owncloud::ssl_chain,
        ssl_key     => $::owncloud::ssl_key,
        ssl_cipher              => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA',
        ssl_protocol            => 'all -SSLv2 -SSLv3',
	headers			=> [ 'always set Strict-Transport-Security "max-age=15768000; includeSubDomains; preload"' ]
      }
    } else {
      apache::vhost { 'owncloud-http':
        servername  => $::owncloud::url,
        port        => $::owncloud::http_port,
        docroot     => $::owncloud::documentroot,
        directories => $vhost_directories,
      }
    }
  }
}
