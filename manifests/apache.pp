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

    apache::vhost { 'owncloud-http':
      servername      => $owncloud::url,
      port            => $owncloud::http_port,
      docroot         => $owncloud::documentroot,
      custom_fragment => $vhost_custom_fragment,
    }
  }
}
