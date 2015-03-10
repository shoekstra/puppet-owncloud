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
    if $::owncloud::ssl {
      apache::vhost { 'owncloud-http':
        servername => $::owncloud::url,
        port       => $::owncloud::http_port,
        docroot    => $::owncloud::documentroot,
        rewrites   => [
          {
            comment      => 'redirect non-SSL traffic to SSL site',
            rewrite_cond => ['%{HTTPS} off'],
            rewrite_rule => ['(.*) https://%{HTTPS_HOST}%{REQUEST_URI}'],
          }
        ]
      }

      apache::vhost { 'owncloud-https':
        servername  => $::owncloud::url,
        port        => $::owncloud::https_port,
        docroot     => $::owncloud::documentroot,
        directories => [
          {
            path            => $::owncloud::documentroot,
            options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
            allow_override  => 'All',
            order           => 'Allow,Deny',
            allow           => 'from All',
            satisfy         => 'Any',
            custom_fragment => 'Dav Off',
          }
        ],
        ssl         => true,
        ssl_ca      => $::owncloud::ssl_ca,
        ssl_cert    => $::owncloud::ssl_cert,
        ssl_chain   => $::owncloud::ssl_chain,
        ssl_key     => $::owncloud::ssl_key,
      }
    } else {
      apache::vhost { 'owncloud-http':
        servername  => $::owncloud::url,
        port        => $::owncloud::http_port,
        docroot     => $::owncloud::documentroot,
        directories => [
          {
            path            => $::owncloud::documentroot,
            options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
            allow_override  => 'All',
            order           => 'Allow,Deny',
            allow           => 'from All',
            satisfy         => 'Any',
            custom_fragment => 'Dav Off',
          }
        ],
      }
    }
  }
}
