# == Class owncloud::apache
#
# This class is called from owncloud
#
class owncloud::apache {

  if $owncloud::manage_apache {
    class { '::apache':
      default_vhost => false,
      mpm_module    => 'prefork',
      purge_configs => false,
    }

    include '::apache::mod::php', '::apache::mod::rewrite', '::apache::mod::ssl'
  }

  if $owncloud::manage_vhost {
  $vhost_custom_fragment = "
  <Directory \"${owncloud::documentroot}\">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Order allow,deny
    Allow from all
    Satisfy Any
    Dav Off
  </Directory>"

    if $owncloud::ssl {
      apache::vhost { 'owncloud-http':
        servername => $owncloud::url,
        port       => $owncloud::http_port,
        docroot    => $owncloud::documentroot,
        rewrites   => [
          {
            comment      => 'redirect non-SSL traffic to SSL site',
            rewrite_cond => ['%{HTTPS} off'],
            rewrite_rule => ['(.*) https://%{HTTPS_HOST}%{REQUEST_URI}'],
          }
        ]
      }

      apache::vhost { 'owncloud-https':
        servername      => $owncloud::url,
        port            => $owncloud::https_port,
        docroot         => $owncloud::documentroot,
        custom_fragment => $vhost_custom_fragment,
        ssl             => true,
        ssl_ca          => $owncloud::ssl_ca,
        ssl_cert        => $owncloud::ssl_cert,
        ssl_chain       => $owncloud::ssl_chain,
        ssl_key         => $owncloud::ssl_key,
      }
    } else {
      apache::vhost { 'owncloud-http':
        servername      => $owncloud::url,
        port            => $owncloud::http_port,
        docroot         => $owncloud::documentroot,
        custom_fragment => $vhost_custom_fragment,
      }
    }
  }
}
